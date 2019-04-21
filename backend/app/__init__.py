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
from app.messages import DOCUMENT_TYPE_UNDEFINED, TABLE_NOT_FOUND, COMPANY_NOT_FOUND, KEY_ERROR, MESSAGE, GENERIC_ERROR, \
    USER_NO_ACCESS
from app.model import db
from app.storage import PostgresDatabase
from app.utils import CbsException, orm_to_json, make_hash


class DocBase(object):
    description = "Документ"

    def __init__(self):
        pass

    @staticmethod
    def build(doc_type):
        if not doc_type:
            raise CbsException(DOCUMENT_TYPE_UNDEFINED)

        try:
            module = importlib.import_module('app.docs.' + doc_type)
            clazz = getattr(module, doc_type.capitalize())
            clazz = clazz()
        except Exception:
            raise CbsException(DOCUMENT_TYPE_UNDEFINED)
        return clazz

    def save(self, bag):
        if '_created' in bag:
            del bag["_created"]
        if '_deleted' in bag:
            del bag["_deleted"]
        if 'date' not in bag['data']:
            bag["data"]['date'] = str(datetime.now())

        if '_id' in bag:
            query = g.tran.query(db.Document).filter_by(_id=bag['_id']) \
                .filter(db.Document.data.contains(type_coerce({"user_id": g.user.id}, JSONB)),
                        db.Document.document_status != 'committed')
            document = query.first()
            if document is None:
                raise CbsException(USER_NO_ACCESS)
        if g.user.roles_id is None:
            raise CbsException(GENERIC_ERROR,
                               u'Вам необходимо получить права')
        else:
            pg_db = PostgresDatabase()
            bag['type'] = 'Document'
            bag['document_status'] = 'draft'
            bag['data']['user_id'] = g.user.id
            if len(g.user.roles_id) > 0:
                bag['approval']['approval_roles'] = []
                for role_id in bag['approval']['roles_id']:
                    bag['approval']['approval_roles'].append({
                        'role_id': role_id
                    })
            _id, _rev = pg_db.store(bag, new_edits=True)
        return {"ok": True, "id": _id, "rev": _rev}

    def saveapproval(self, bag):
        if '_created' in bag:
            del bag["_created"]
        if '_deleted' in bag:
            del bag["_deleted"]
        if 'date' not in bag['data']:
            bag["data"]['date'] = str(datetime.now())

        if '_id' in bag:
            query = g.tran.query(db.Document).filter_by(_id=bag['_id']) \
                .filter(db.Document.document_status != 'committed')
            document = query.first()
            if document is None:
                raise CbsException(USER_NO_ACCESS)

        pg_db = PostgresDatabase()
        bag['type'] = 'Document'
        bag['document_status'] = 'draft'
        if len(g.user.roles_id) > 0:
            bag['approval']['approval_roles'] = []
            for role_id in bag['approval']['roles_id']:
                bag['approval']['approval_roles'].append({
                    'role_id': role_id
                })
        _id, _rev = pg_db.store(bag, new_edits=True)
        return {"ok": True, "id": _id, "rev": _rev}

    def approvep(self, bag, approve, comment):
        roles_filter = []
        for role_id in g.user.roles_id:
            roles_filter.append(
                db.Document.approval.contains(type_coerce({'approval_roles': [{"role_id": role_id}]}, JSONB)))
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

        dd_hash = make_hash(doc_data)
        bag_hash = make_hash(bag)

        if doc_data['document_status'] == 'draft':
            doc_data['document_status'] = 'approval' if \
                'required' in doc_data['approval'] and doc_data['approval']['required'] == True else 'approved'
            pg_db = PostgresDatabase()
            doc_data['type'] = 'Document'
            del doc_data["_created"]
            del doc_data["_deleted"]
            _id, _rev = pg_db.store(doc_data)
            return {"id": _id, "rev": _rev}
        elif doc_data['document_`status'] == 'approval':
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
                                    if approval_position == len(
                                            doc_data['approval']["approval_roles"]) - 1:
                                        doc_data['document_status'] = 'approved'
                                except IndexError:
                                    pass
                        else:
                            approval_role["approved"] = True
                            try:
                                if approval_position == len(
                                        doc_data['approval']["approval_roles"]) - 1:
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
            if dd_hash == bag_hash:
                _id, _rev = pg_db.store(doc_data)
                return {"id": _id, "rev": _rev}
            else:
                ar_indexes = []
                ar_index = 0
                for ar in doc_data['approval']['approval_roles']:
                    if "approval_users" not in ar:
                        ar_indexes.append(ar_index)
                    ar_index += 1
                for index in ar_indexes:
                    del doc_data['approval']['approval_roles'][index]
                for role_id in doc_data['approval']['roles_id']:
                    doc_data['approval']['approval_roles'].append({
                        "role_id": role_id
                    })
                bag['type'] = 'Document'
                bag['document_status'] = 'approval'
                bag['approval'] = doc_data['approval']
                bag['data']['executor_id'] = None
                bag['data']['user_id'] = doc_data['data']['user_id']
                _id, _rev = pg_db.store(bag)
                return {"id": _id, "rev": _rev}
        elif doc_data['document_status'] == 'approved':
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

            if doc_data['data']["executor_id"] == g.user.id and\
                    (dd_hash == bag_hash or 'roles_id' not in doc_data['approval']):
                return self.commit(bag)
            elif doc_data['data']["executor_id"] == g.user.id and dd_hash != bag_hash:
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

    @staticmethod
    def listing(bag):
        query = g.tran.query(db.Document._id).filter_by(_deleted='infinity', company_id=g.session['company_id'])
        doc_vars = vars(db.Document)
        for var in doc_vars:
            if isinstance(doc_vars[var], InstrumentedAttribute):
                query = query.add_column(doc_vars[var])

        query = query.filter(
            or_(db.Document.data.contains(type_coerce({"user_id": g.user.id}, JSONB)),
                db.Document.data.contains(type_coerce({"executor_id": g.user.id}, JSONB)),
                type_coerce(db.Document.approval['roles_id'], JSONB).has_any(array(g.user.roles_id)) if len(
                    g.user.roles_id) > 0 else None))

        if "own" in bag and bag["own"] is True:
            query = query.filter(db.Document.data['user_id'] == g.user.id)
        else:
            query = query.filter(db.Document.document_status != 'draft')

        if "filter" in bag:
            if "data" in bag["filter"] and isinstance(bag["filter"]["data"], dict):
                query = query.filter(db.Document.data.contains(type_coerce(bag["filter"]["data"], JSONB)))
                del bag["filter"]["data"]
            query = query.filter_by(**bag["filter"])

        if "order_by" in bag:
            query = query.order_by(*bag["order_by"])
        else:
            query = query.order_by(db.Document._created.desc())

        count = query.count()
        if "limit" in bag:
            query = query.limit(bag["limit"])
        if "offset" in bag:
            query = query.offset(bag["offset"])

        if 'with_related' in bag and bag['with_related'] is True:
            document_status_value = g.tran.query(
                func.row_to_json(text('enums.*'))).select_from(db.Enums) \
                .filter_by(_deleted='infinity', name='document_status') \
                .filter(db.Enums.data['key'].cast(TEXT) == cast(db.Document.document_status, TEXT)) \
                .as_scalar().label('document_status_value')

            document_type_value = g.tran.query(
                func.row_to_json(text('enums.*'))).select_from(db.Enums) \
                .filter_by(_deleted='infinity', name='document_type') \
                .filter(db.Enums.data['key'].cast(TEXT) == cast(db.Document.document_type, TEXT)) \
                .as_scalar().label('document_type_value')

            roles = g.tran.query(func.jsonb_agg(func.row_to_json(text('roles.*')))).select_from(db.Roles) \
                .filter_by(_deleted='infinity')\
                .filter(type_coerce(db.Document.approval['roles_id'], JSONB).has_any(array([db.Roles._id])))\
                .as_scalar().label('roles')

            entry_user = g.tran.query(func.json_build_object(
                "id", db.User.id, "username", db.User.username, "email", db.User.email, "rec_date", db.User.rec_date,
                "data", db.User.data, "role", db.User.role)).select_from(db.User).filter_by(
                id=db.Document.entry_user_id) \
                .as_scalar().label('entry_user')

            query = query.add_columns(document_status_value, document_type_value, entry_user, roles)

        return {'docs': orm_to_json(query.all()), 'count': count}

    def get(self, bag):
        query = g.tran.query(db.Document).filter_by(_deleted='infinity', _id=bag[ID])
        query = query.filter(
            or_(db.Document.data.contains(type_coerce({"user_id": g.user.id}, JSONB)),
                db.Document.data.contains(type_coerce({"executor_id": g.user.id}, JSONB)),
                type_coerce(db.Document.approval['roles_id'], JSONB).has_any(array(g.user.roles_id)) if len(
                    g.user.roles_id) > 0 else None))

        doc = query.one()
        return {'docs': orm_to_json(doc)}

    @abc.abstractmethod
    def check(self, bag):
        pass

    @abc.abstractmethod
    def commit(self, bag):
        pass

    @abc.abstractmethod
    def rollback(self, bag):
        pass

    @classmethod
    def all(cls):
        inst = []
        basePath = os.path.join(os.path.dirname(os.path.realpath("__main__")), 'app/docs')
        basePath = basePath.replace('/tests', '')
        for file in glob.glob1(basePath, '*.py'):
            try:
                i = imp.load_source(file.split('.')[0], os.path.join(basePath, file))
                for name, obj in inspect.getmembers(i, inspect.isclass):
                    if DocBase.__name__ != name and issubclass(obj, DocBase):
                        inst.append({'id': name.lower(), 'name': obj.description})
            except Exception as e:
                pass
        return inst
