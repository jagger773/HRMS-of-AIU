# coding=utf-8
import abc
import glob
import imp
import importlib
import inspect
import os
from datetime import datetime

from flask import g
from sqlalchemy import or_, and_, type_coerce, cast, text, func
from sqlalchemy.dialects.postgresql import JSONB, array, TEXT
from sqlalchemy.orm.attributes import InstrumentedAttribute

from app.keys import ID
from app import DocBase, CbsException
from app.messages import NOT_ENOUGH_PARAMETER
from app.service import doc
from app.messages import DOCUMENT_TYPE_UNDEFINED, TABLE_NOT_FOUND, COMPANY_NOT_FOUND, KEY_ERROR, MESSAGE, GENERIC_ERROR, \
    USER_NO_ACCESS
from app.model import db
from app.storage import PostgresDatabase
from app.utils import CbsException, orm_to_json, make_hash

class Forum(DocBase):
    description = "Форум"

    def commit(self, bag):
        pass

    def rollback(self, bag):
        pass

    def check(self, bag):
        pass

    def approve(self, bag, approve, comment):
        roles_filter = []
        for role_id in g.user.roles_id:
            roles_filter.append(db.Document.approval.contains(type_coerce({'approval_roles': [{"role_id": role_id}]}, JSONB)))
        query = g.tran.query(db.Document).filter_by(_id=bag[ID] if ID in bag else bag['_id'], _deleted='infinity') \
            .filter(or_(and_(db.Document.document_status == "approval", or_(*roles_filter)),
                        and_(db.Document.document_status == "approved",
                             db.Document.data.contains(type_coerce({'executor_id': g.user.id}, JSONB))),
                        and_(db.Document.document_status == 'draft',
                             db.Document.data.contains(type_coerce({'user_id': g.user.id}, JSONB)))))
        document = query.first()
        if document is None:
            raise CbsException(USER_NO_ACCESS)
        doc_data = orm_to_json(document)

        del doc_data["_created"]
        del doc_data["_deleted"]
        del doc_data["entry_user_id"]

        if bag['document_status'] == 'draft' and doc_data['document_status'] == 'draft':
            doc_data['document_status'] = 'approval'if \
                'required' in doc_data['approval'] and doc_data['approval']['required'] == True else 'approved'
            pg_db = PostgresDatabase()
            doc_data['type'] = 'Document'
            _id, _rev = pg_db.store(doc_data)
            return {"id": _id, "rev": _rev}
        elif bag['document_status'] == 'approval' and doc_data['document_status'] == 'approval':
            approval_position = 0
            for approval_role in doc_data['approval']["approval_roles"]:
                if g.user.roles_id.index(approval_role["role_id"]) >= 0 and "approved" not in approval_role:
                    if "approval_users" in approval_role:
                        for approval_users in approval_role["approval_users"]:
                            if approval_users["user_id"] == g.user.id:
                                raise CbsException(GENERIC_ERROR, u'Вы уже одобряли документ')
                        approval_role["approval_users"].append({
                            "user_id": g.user.id,
                            "approved": approve
                        })
                    else:
                        approval_role["approval_users"] = []
                        approval_role["approval_users"].append({
                            "user_id": g.user.id,
                            "approved": approve
                        })
                    if approve is True:
                        if doc_data['approval']["approval_type"] == 'all':
                            users_count = g.tran.query(db.User).filter_by(_deleted='infinity') \
                                .filter(db.User.roles_id.contains(type_coerce(approval_role["role_id"], JSONB)))
                            if users_count == len(approval_role["approval_users"]):
                                approval_role["approved"] = True
                                try:
                                    if approval_position == len(doc_data['approval']["approval_roles"]) - 1:
                                        doc_data['document_status'] = 'approved'
                                except IndexError:
                                    pass
                        else:
                            approval_role["approved"] = True
                            try:
                                if approval_position == len(doc_data['approval']["approval_roles"]) - 1:
                                    doc_data['document_status'] = 'approved'
                            except IndexError:
                                pass
                    else:
                        approval_role["approved"] = False
                        doc_data['document_status'] = 'rejected'
                    break
                approval_position += 1
            pg_db = PostgresDatabase()

            if comment:
                pg_db.store({
                    "type": "DocumentComments",
                    "document_id": doc_data['_id'],
                    "data": {
                        "comment_type": "approval" if approve is True else "rejection",
                        "comment": comment
                    }
                })

            doc_data['type'] = 'Document'
            _id, _rev = pg_db.store(doc_data)
            return {"id": _id, "rev": _rev}
        elif bag['document_status'] == 'approved' and doc_data['document_status'] == 'approved':
            pg_db = PostgresDatabase()

            if comment:
                pg_db.store({
                    "type": "DocumentComments",
                    "document_id": doc_data['_id'],
                    "data": {
                        "comment_type": "commit",
                        "comment": comment
                    }
                })

            if doc_data['data']["executor_id"] == g.user.id and \
                ('roles_id' not in doc_data['approval']):
                return self.commit(bag)
            elif doc_data['data']["executor_id"] == g.user.id:
                for role_id in doc_data['approval']['roles_id']:
                    doc_data['approval']['approval_roles'].append({
                        "role_id": role_id
                    })
                bag['type'] = 'Document'
                bag['document_status'] = 'approval'
                bag['approval'] = doc_data['approval']
                bag['data']['executor_id'] = doc_data['data']['executor_id']
                bag['data']['user_id'] = doc_data['data']['user_id']
                _id, _rev = pg_db.store(bag)
                return {"id": _id, "rev": _rev}

        raise CbsException(GENERIC_ERROR, u'Не подходящий статус документа')

    def listing(bag):
        pass
