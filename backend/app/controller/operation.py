# coding=utf-8
from datetime import datetime

from flask import g
from sqlalchemy import func, text, cast, type_coerce, INTEGER
from sqlalchemy.dialects.postgresql import JSONB, array, TEXT
from sqlalchemy.orm.attributes import InstrumentedAttribute

from app import PostgresDatabase, ID, orm_to_json
from app.model import db


def put(bag):
    pg_db = PostgresDatabase()

    operation_data = {
        "type": "Operations",
        "branch_id": bag['branch_id'],
        "document_id": bag['document_id'],
        "product_id": bag['product_id'],
        "unit_id": bag['unit_id'],
        "quantity": bag['quantity'],
        "currency_id": bag['currency_id'],
        "purpose_id": bag.get('purpose_id', None),
        "quote_unit_price": bag['quote_unit_price'],
        "total_cost": bag['total_cost'],
        "additional_cost": bag.get('additional_cost', 0),
        "delivery_date": bag.get('delivery_date', None),
        "is_due": bag.get('is_due', False),
        "due_date": bag.get('due_date', None),
        "is_advance": bag.get('is_advance', None),
        "employee_id": bag.get('employee_id', None),
        "contractor_id": bag.get('contractor_id', None),
        "from_branch_id": bag.get('from_branch_id', None),
        "comment": bag.get('comment', None),
        "operation_status": bag.get('operation_status', 'active')
    }
    if '_id' in bag:
        operation_data['_id'] = bag['_id']
    if '_rev' in bag:
        operation_data['_rev'] = bag['_rev']
    _id, _rev = pg_db.store(operation_data, new_edits=True)
    return {"id": _id, "rev": _rev}


def get(bag):
    query = g.tran.query(db.Operations._id)\
        .filter_by(_deleted='infinity', _id=bag[ID], company_id=g.session['company_id'])
    operation_vars = vars(db.Operations)
    for operation_var in operation_vars:
        if isinstance(operation_vars[operation_var], InstrumentedAttribute):
            query = query.add_column(operation_vars[operation_var])
    if 'with_related' in bag and bag['with_related'] is True:
        query = find_relations(query)
    operation = orm_to_json(query.one())
    return {'operation': operation}


def listing(bag):
    query = g.tran.query(db.Operations._id).filter_by(_deleted='infinity', company_id=g.session['company_id'])
    operation_vars = vars(db.Operations)
    for operation_var in operation_vars:
        if isinstance(operation_vars[operation_var], InstrumentedAttribute):
            query = query.add_column(operation_vars[operation_var])

    if "filter" in bag:
        query = query.filter_by(**bag["filter"])

    if "order_by" in bag:
        query = query.order_by(*bag["order_by"])
    else:
        query = query.order_by(db.Operations._created.desc())

    count = query.count()
    if "limit" in bag:
        query = query.limit(bag["limit"])
    if "offset" in bag:
        query = query.offset(bag["offset"])
    if 'with_related' in bag and bag['with_related'] is True:
        query = find_relations(query)
    operations = query.all()
    operations = orm_to_json(operations)
    return {'operations': operations, 'count': count}


def find_relations(query):
    branch = g.tran.query(func.row_to_json(text('branches.*'))).select_from(db.Branches) \
        .filter_by(_deleted='infinity', _id=db.Operations.branch_id).as_scalar().label('branch')

    purpose = g.tran.query(func.row_to_json(text('costcenterpurposes.*'))).select_from(db.CostCenterPurposes) \
        .filter_by(_deleted='infinity', _id=db.Operations.purpose_id).as_scalar().label('purpose')

    document = g.tran.query(func.row_to_json(text('document.*'))).select_from(db.Document) \
        .filter_by(_deleted='infinity', _id=db.Operations.document_id).as_scalar().label('document')

    product = g.tran.query(func.row_to_json(text('products.*'))).select_from(db.Products) \
        .filter_by(_deleted='infinity', _id=db.Operations.product_id).as_scalar().label('product')

    unit = g.tran.query(func.row_to_json(text('units.*'))).select_from(db.Units) \
        .filter_by(_deleted='infinity', _id=db.Operations.unit_id).as_scalar().label('unit')

    currency = g.tran.query(func.row_to_json(text('currencies.*'))).select_from(db.Currencies) \
        .filter_by(_deleted='infinity', _id=db.Operations.currency_id).as_scalar().label('currency')

    operation_status = g.tran.query(func.row_to_json(text('enums.*'))).select_from(db.Enums) \
        .filter_by(_deleted='infinity', name='operation_status') \
        .filter(db.Enums.data['key'].cast(TEXT) == cast(db.Operations.operation_status, TEXT)) \
        .as_scalar().label('operation_status_value')

    user = g.tran.query(func.json_build_object(
        "id", db.User.id, "username", db.User.username, "email", db.User.email, "rec_date", db.User.rec_date,
        "data", db.User.data, "role", db.User.role)).select_from(db.User).filter_by(id=db.UserCompany.user_id) \
        .as_scalar().label('user')

    employee = g.tran.query(func.json_build_object('_id', db.UserCompany._id,
                                                   '_rev', db.UserCompany._rev,
                                                   '_created', db.UserCompany._created,
                                                   'user_id', db.UserCompany.user_id,
                                                   'company_id', db.UserCompany.company_id,
                                                   'entry_user_id', db.UserCompany.entry_user_id,
                                                   'branches_id', db.UserCompany.branches_id,
                                                   'roles_id', db.UserCompany.roles_id,
                                                   'access', db.UserCompany.access,
                                                   'user', user)).select_from(db.UserCompany) \
        .filter_by(_deleted='infinity', company_id=db.Operations.company_id, user_id=db.Operations.employee_id)\
        .as_scalar().label('employee')

    contractor = g.tran.query(func.row_to_json(text('contractors.*'))).select_from(db.Contractors) \
        .filter_by(_deleted='infinity', _id=db.Operations.contractor_id).as_scalar().label('contractor')

    branch2 = g.tran.query(func.row_to_json(text('branches.*'))).select_from(db.Branches) \
        .filter_by(_deleted='infinity', _id=db.Operations.from_branch_id).as_scalar().label('branch2')

    entry_user = g.tran.query(func.json_build_object(
        "id", db.User.id, "username", db.User.username, "email", db.User.email, "rec_date", db.User.rec_date,
        "data", db.User.data, "role", db.User.role)).select_from(db.User).filter_by(id=db.Operations.entry_user_id)\
        .as_scalar().label('entry_user')

    query = query.add_columns(branch, purpose, document, product, unit, currency, contractor,
                              branch2, entry_user, employee, operation_status)
    return query
