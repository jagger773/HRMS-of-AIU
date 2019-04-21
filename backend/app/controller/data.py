import re
import os

from flask import g
from spyne.store.relational import document
from sqlalchemy import or_, type_coerce, func, text, cast
from sqlalchemy.dialects.mysql import TEXT
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm.attributes import InstrumentedAttribute
from datetime import datetime

from app.keys import ID, IDS
from app.messages import TABLE_NOT_FOUND, USER_NO_ACCESS, COMPANY_NOT_FOUND, KEY_ERROR, MESSAGE
from app.model import db
from app.service import is_admin
from app.storage import PostgresDatabase
from app.utils import orm_to_json, CbsException
from run import app


def put(bag):
    data = {
        "type": bag["type"]
    }
    del bag["type"]
    if '_created' in bag:
        del bag["_created"]
    if '_deleted' in bag:
        del bag["_deleted"]

    table_name = data["type"]
    table = getattr(db, table_name)

    if table is None or not issubclass(table, (db.Base, db.CouchSync)):
        raise CbsException(TABLE_NOT_FOUND)

    for key in bag:
        data[key] = bag[key]
    # del_columns(data)

    for column in table.metadata.tables.get(table_name.lower()).columns._data:
        nullable = table.metadata.tables.get(table_name.lower()).columns._data[column].nullable
        if not nullable and not column.startswith("_") and not column == "entry_user_id" and column not in data:
            print data
            raise CbsException(KEY_ERROR, MESSAGE.get(KEY_ERROR).format(column))
        elif not column.startswith("_") and not column == "entry_user_id" and column not in data:
            data[column] = None

    pg_db = PostgresDatabase()
    _id, _rev = pg_db.store(data, new_edits=True)
    return {"ok": True, "id": _id, "rev": _rev}


def get(bag):
    table_name = bag['type']
    table = getattr(db, table_name) if hasattr(db, table_name) else None
    if table is None or not issubclass(table, (db.Base, db.CouchSync)):
        raise CbsException(TABLE_NOT_FOUND)
    query = g.tran.query(table).filter_by(_deleted='infinity', _id=bag[ID])

    entity = orm_to_json(query.one())

    if "with_related" in bag and bag["with_related"] == True:
        entity = find_relations(entity, table_name)

    return {'doc': entity}


def delete(bag):
    table_name = bag['type']
    table = getattr(db, table_name) if hasattr(db, table_name) else None
    query = g.tran.query(table).filter_by(_id=u"{}".format(bag['id']))
    query.update({"_deleted": str(datetime.now())})
    doc = query.one()
    files = doc.data["files"]
    for f in files:
        file_path = os.path.join(app.config['UPLOADED_DEFAULTS_DEST'], f["filename"])
        os.remove(file_path)
    return {'ok': True}


def remove(bag):
    table_name = bag["type"]
    table = getattr(db, table_name)

    if table is None or not issubclass(table, (db.Base, db.CouchSync)):
        raise CbsException(TABLE_NOT_FOUND)

    if not is_admin():
        item_query = g.tran.query(table).filter_by(_deleted="infinity", _id=bag["_id"])
        item_query = item_query.first()
        if item_query is None:
            raise CbsException(USER_NO_ACCESS)

    pg_db = PostgresDatabase()
    _id, _rev = pg_db.remove(bag["_id"], bag["_rev"])
    return {"ok": True, "id": _id, "rev": _rev}


def listing(bag):
    table_name = bag["type"]
    table = getattr(db, table_name) if hasattr(db, table_name) else None

    if table is None or not issubclass(table, (db.Base, db.CouchSync)):
        raise CbsException(TABLE_NOT_FOUND)
    query = g.tran.query(table._id).filter_by(_deleted='infinity')

    doc_vars = vars(table)
    for var in doc_vars:
        if isinstance(doc_vars[var], InstrumentedAttribute):
            query = query.add_column(doc_vars[var])

    if table == db.Menus:
        if not is_admin():
            menus_id = []
            roles = g.tran.query(db.Roles).filter_by(_deleted='infinity') \
                .filter(db.Roles._id.in_(g.user.roles_id if g.user.roles_id is not None else [])).all()
            for role in roles:
                menus_id.extend(role.menus_id)
            query = query.filter(db.Menus._id.in_(menus_id))
    if table == db.Journals:
        if not is_admin():
            query = g.tran.query(db.Journals).filter(db.Journals.entry_user_id == g.user.id)
    if table == db.Queue:
        dissov = g.tran.query(db.Dissov).filter_by(_deleted='infinity')\
            .filter(db.Dissov.secretary == g.user.id).first()
        query = query.filter(table.dissov_id == dissov._id)
    if table == db.New:
        if "sectionsofpublication_id" in bag:
            query = query.filter(db.New.sectionsofpublication_id == bag["sectionsofpublication_id"])
            del bag["sectionsofpublication_id"]
    if table == db.Dcomposition:
        if "dissov_id" in bag:
            query = query.filter(db.Dcomposition.dissov_id == bag["dissov_id"])
            del bag["dissov_id"]
    if table == db.Theme:
        if 'user_id' in bag:
            query = query.filter(table.entry_user_id == bag["user_id"])
            del bag["user_id"]
        if 'search' in bag:
            query = query.filter(or_(func.concat(table.name, ' ')).ilike(
                u"%{0}%".format(bag['search'])))
            del bag["search"]

    if "filter" in bag:
        if 'filter' in bag and 'user_id' in bag['filter']:
            query = query.filter(table.user_id == bag["filter"]["user_id"])
            del bag["filter"]["user_id"]
        if 'filter' in bag and 'academicdegree_id' in bag['filter']:
            query = query.filter(table.academicdegree_id == bag["filter"]["academicdegree_id"])
            del bag["filter"]["academicdegree_id"]
        if 'filter' in bag and 'branchesofscience_id' in bag['filter']:
            query = query.filter(table.branchesofscience_id == bag["filter"]["branchesofscience_id"])
            del bag["filter"]["branchesofscience_id"]
        if 'filter' in bag and 'specialty_id' in bag['filter']:
            query = query.filter(table.specialty_id == bag["filter"]["specialty_id"])
            del bag["filter"]["specialty_id"]
        if "data" in bag["filter"] and isinstance(bag["filter"]["data"], dict):
            query = query.filter(table.data.contains(type_coerce(bag["filter"]["data"], JSONB)))
            del bag["filter"]["data"]
        query = query.filter_by(**bag["filter"])

    if 'search' in bag:
        query = query.filter(or_(func.concat(table.name_ru, ' ', table.name_kg, '')).ilike(u"%{}%".format(bag['search'])))
        del bag["search"]

    if 'user_id' in bag:
        query = query.filter(table.user_id == bag["user_id"])
        del bag["user_id"]

    if "order_by" in bag:
        query = query.order_by(*bag["order_by"])

    elif bag.get(IDS) and hasattr(table, "_id"):
        query = query.filter(table._id.in_(bag.get(IDS)))

    count = query.count()
    if "limit" in bag:
        query = query.limit(bag["limit"])
    if "offset" in bag:
        query = query.offset(bag["offset"])

    if "with_related" in bag and bag["with_related"] is True:
        if table == db.Documents:
            theme = g.tran.query(func.jsonb_agg(func.row_to_json(text('theme.*')))) \
                .select_from(db.Theme) \
                .filter_by(_deleted='infinity').filter(
                db.Theme._id == db.Documents.theme_id).as_scalar() \
                .label('theme')

            query = query.add_columns(theme)

        if table == db.Userdegree:
            degreespeciality = g.tran.query(func.jsonb_agg(func.row_to_json(text('degreespeciality.*')))) \
                .select_from(db.Degreespeciality) \
                .filter_by(_deleted='infinity').filter(db.Degreespeciality.userdegree_id == db.Userdegree._id).as_scalar() \
                .label('degreespeciality')

            query = query.add_columns(degreespeciality)

        if table == db.Dissov:

            programs = g.tran.query(func.jsonb_agg(func.row_to_json(text('dspecialty.*'))))\
                .select_from(db.Dspecialty)\
                .filter_by(_deleted='infinity').filter(db.Dspecialty.dissov_id == db.Dissov._id).as_scalar()\
                .label('programs')

            compositions = g.tran.query(func.jsonb_agg(func.row_to_json(text('dcomposition.*')))) \
                .select_from(db.Dcomposition) \
                .filter_by(_deleted='infinity').filter(db.Dcomposition.dissov_id == db.Dissov._id).as_scalar() \
                .label('compositions')

            query = query.add_columns(programs, compositions)

        if table == db.DisApplication:

            application_status = g.tran.query(
                func.row_to_json(text('enums.*'))).select_from(db.Enums) \
                .filter_by(_deleted='infinity', name='status') \
                .filter(db.Enums.data['key'].cast(TEXT) == cast(db.DisApplication.status, TEXT)) \
                .as_scalar().label('application_status')

            theme = g.tran.query(func.jsonb_agg(func.row_to_json(text('theme.*')))) \
                .select_from(db.Theme) \
                .filter_by(_deleted='infinity').filter(
                db.Documents._id == db.DisApplication.document_id, db.Theme._id == db.Documents.theme_id).as_scalar() \
                .label('theme')

            remark = g.tran.query(func.jsonb_agg(func.row_to_json(text('disremarks.*')))) \
                .select_from(db.DisRemarks) \
                .filter_by(_deleted='infinity').filter(
                db.DisRemarks.dissov_id == db.DisApplication.dissov_id).as_scalar() \
                .label('remark')

            query = query.add_columns(application_status, theme, remark)

    result = orm_to_json(query.all())
    if "with_related" in bag and bag["with_related"] is True:
        result = find_relations(result, table_name)

    return {"docs": result, "count": count}


def find_relations(row, related_table_name):
    if not isinstance(row, dict) and not isinstance(row, list):
        return row
    if isinstance(row, list):
        rel_column = []
        for r in row:
            rel_column.append(find_relations(r, related_table_name))
        return rel_column
    rel_column = {}
    if '_deleted' in row:
        del row['_deleted']
    for column in row:
        if re.match("[\w_]+_id", column) and (isinstance(row[column], basestring) or isinstance(row[column], int)):
            rel_table_name = ""
            up = True
            for char in column[:-3]:
                if up:
                    rel_table_name += char.upper()
                    up = False
                elif char != "_":
                    rel_table_name += char
                if char == "_":
                    up = True
            if rel_table_name == "Parent":
                related_table = getattr(db, related_table_name) if hasattr(db, related_table_name) else None
            elif rel_table_name == "EntryUser" or rel_table_name == "Executor":
                related_table = db.User
            else:
                related_table = getattr(db, rel_table_name) if hasattr(db, rel_table_name) else None
                if related_table is None:
                    rel_table_name_copy = rel_table_name[:-1] + 'ies' if \
                        rel_table_name.endswith('y') else rel_table_name + 'es'
                    related_table = getattr(db, rel_table_name_copy) if hasattr(db, rel_table_name_copy) else None
                if related_table is None:
                    rel_table_name_copy = rel_table_name + 's'
                    related_table = getattr(db, rel_table_name_copy) if hasattr(db, rel_table_name_copy) else None
            if related_table is not None:
                if issubclass(related_table, db.CouchSync):
                    rel_table_data = g.tran.query(related_table).filter_by(_deleted='infinity', _id=row[column])
                    rel_table_data = rel_table_data.first()
                else:
                    rel_table_data = g.tran.query(related_table).filter_by(id=row[column])
                    rel_table_data = rel_table_data.first()
                if rel_table_data is not None:
                    rel_table_data = orm_to_json(rel_table_data)
                    if issubclass(related_table, db.CouchSync):
                        del rel_table_data["_deleted"]
                    if 'password' in rel_table_data:
                        del rel_table_data['password']
                    if 'secure' in rel_table_data:
                        del rel_table_data['secure']
                    rel_column[column[:-3]] = rel_table_data
            rel_column[column] = row[column]
        elif isinstance(row[column], dict) or isinstance(row[column], list):
            if isinstance(row[column], list) and re.match("[\w_]+_id", column):
                rel_table_name = ""
                up = True
                for char in column[:-3]:
                    if up:
                        rel_table_name += char.upper()
                        up = False
                    elif char != "_":
                        rel_table_name += char
                    if char == "_":
                        up = True
                related_table = getattr(db, rel_table_name) if hasattr(db, rel_table_name) else None
                if related_table is not None:
                    rel_table_data = g.tran.query(related_table)
                    if issubclass(related_table, db.CouchSync):
                        rel_table_data = rel_table_data.filter_by(_deleted='infinity') \
                            .filter(related_table._id.in_(row[column]))
                    else:
                        rel_table_data = rel_table_data.filter(related_table.id.in_(row[column]))
                    rel_table_data = orm_to_json(rel_table_data.all())
                    for rel_table_data_item in rel_table_data:
                        if issubclass(related_table, db.CouchSync):
                            del rel_table_data_item["_deleted"]
                        if 'password' in rel_table_data_item:
                            del rel_table_data_item['password']
                        if 'secure' in rel_table_data_item:
                            del rel_table_data_item['secure']
                    rel_column[column[:-3]] = rel_table_data
            rel_column[column] = find_relations(row[column], related_table_name)
        else:
            if column == 'document_type':
                doc_types = document.all({})['doc_types']
                for doc_type in doc_types:
                    if doc_type['id'] == row[column]:
                        rel_column[str.format('{}_value', column)] = doc_type['name']
            elif isinstance(row[column], basestring):
                rel_enum = g.tran.query(db.Enums).filter_by(name=column) \
                    .filter(db.Enums.data.contains(type_coerce({"key": row[column]}, JSONB))).first()
                if rel_enum is not None:
                    rel_column[str.format('{}_value', column)] = rel_enum.data['name']
            rel_column[column] = row[column]
    return rel_column


def del_columns(data):
    cols_to_del = []
    for key in data:
        for key1 in data:
            if key[:-3] == key1 or str.format('{}_value', key) == key1:
                cols_to_del.append(key1)
    for col_to_del in cols_to_del:
        del data[col_to_del]
    for key in data:
        if isinstance(data[key], dict):
            del_columns(data[key])
