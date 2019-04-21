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

    accounting_data = {
        "type": "Payments",
        "branch_id": bag['branch_id'],
        "document_id": bag.get('document_id', None),
        "amount": bag['amount'],
        "currency_id": bag['currency_id'],
        "payment_date": bag['payment_date'] if 'payment_date' in bag else datetime.now(),
        "payment_direction": bag['payment_direction'],
        "payment_status": bag.get('payment_status', 'active'),
        "payment_type": bag['payment_type'],
        "data": {}
    }
    if '_id' in bag:
        accounting_data['_id'] = bag['_id']
    if '_rev' in bag:
        accounting_data['_rev'] = bag['_rev']
    if 'employee_id' in bag['data']:
        accounting_data['data']['employee_id'] = bag['data']['employee_id']
    if 'contractor_id' in bag['data']:
        accounting_data['data']['contractor_id'] = bag['data']['contractor_id']
    if 'branch_id' in bag['data']:
        accounting_data['data']['branch_id'] = bag['data']['branch_id']
    if 'comment' in bag['data']:
        accounting_data['data']['comment'] = bag['data']['comment']
    _id, _rev = pg_db.store(accounting_data, new_edits=True)
    return {"id": _id, "rev": _rev}


def get(bag):
    query = g.tran.query(db.Payments._id)\
        .filter_by(_deleted='infinity', _id=bag[ID], company_id=g.session['company_id'])
    payment_vars = vars(db.Payments)
    for payment_var in payment_vars:
        if isinstance(payment_vars[payment_var], InstrumentedAttribute):
            query = query.add_column(payment_vars[payment_var])
    if 'with_related' in bag and bag['with_related'] is True:
        query = find_relations(query)
    payment = orm_to_json(query.one())
    return {'payment': payment}


def listing(bag):
    query = g.tran.query(db.Payments._id).filter_by(_deleted='infinity', company_id=g.session['company_id'])
    payment_vars = vars(db.Payments)
    for payment_var in payment_vars:
        if isinstance(payment_vars[payment_var], InstrumentedAttribute):
            query = query.add_column(payment_vars[payment_var])

    if "filter" in bag:
        if "data" in bag["filter"] and isinstance(bag["filter"]["data"], dict):
            query = query.filter(db.Payments.data.contains(type_coerce(bag["filter"]["data"], JSONB)))
            del bag["filter"]["data"]
        query = query.filter_by(**bag["filter"])

    if "order_by" in bag:
        query = query.order_by(*bag["order_by"])
    else:
        query = query.order_by(db.Payments._created.desc())

    count = query.count()
    if "limit" in bag:
        query = query.limit(bag["limit"])
    if "offset" in bag:
        query = query.offset(bag["offset"])
    if 'with_related' in bag and bag['with_related'] is True:
        query = find_relations(query)
    payments = query.all()
    payments = orm_to_json(payments)
    return {'payments': payments, 'count': count}


def find_relations(query):

    branch = g.tran.query(func.row_to_json(text('branches.*'))).select_from(db.Branches) \
        .filter_by(_deleted='infinity', _id=db.Payments.branch_id).as_scalar().label('branch')

    document = g.tran.query(func.row_to_json(text('document.*'))).select_from(db.Document) \
        .filter_by(_deleted='infinity', _id=db.Payments.document_id).as_scalar().label('document')

    currency = g.tran.query(func.row_to_json(text('currencies.*'))).select_from(db.Currencies) \
        .filter_by(_deleted='infinity', _id=db.Payments.currency_id).as_scalar().label('currency')

    payment_direction = g.tran.query(func.row_to_json(text('enums.*'))).select_from(db.Enums) \
        .filter_by(_deleted='infinity', name='payment_direction') \
        .filter(db.Enums.data['key'].cast(TEXT) == cast(db.Payments.payment_direction, TEXT)) \
        .as_scalar().label('payment_direction_value')

    payment_type = g.tran.query(func.row_to_json(text('enums.*'))).select_from(db.Enums) \
        .filter_by(_deleted='infinity', name='payment_type') \
        .filter(db.Enums.data['key'].cast(TEXT) == cast(db.Payments.payment_type, TEXT)) \
        .as_scalar().label('payment_type_value')

    payment_status = g.tran.query(func.row_to_json(text('enums.*'))).select_from(db.Enums) \
        .filter_by(_deleted='infinity', name='payment_status') \
        .filter(db.Enums.data['key'].cast(TEXT) == cast(db.Payments.payment_status, TEXT)) \
        .as_scalar().label('payment_status_value')

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
        .filter_by(_deleted='infinity', company_id=db.Payments.company_id, user_id=db.Payments.data['employee_id']
                   .cast(INTEGER))\
        .as_scalar().label('employee')

    contractor = g.tran.query(func.row_to_json(text('contractors.*'))).select_from(db.Contractors) \
        .filter_by(_deleted='infinity', _id=db.Payments.data['contractor_id'].cast(TEXT)) \
        .as_scalar().label('contractor')

    branch2 = g.tran.query(func.row_to_json(text('branches.*'))).select_from(db.Branches) \
        .filter_by(_deleted='infinity', _id=db.Payments.data['branch_id'].cast(TEXT)).as_scalar().label('branch2')

    entry_user = g.tran.query(func.json_build_object(
        "id", db.User.id, "username", db.User.username, "email", db.User.email, "rec_date", db.User.rec_date,
        "data", db.User.data, "role", db.User.role)).select_from(db.User).filter_by(id=db.Payments.entry_user_id)\
        .as_scalar().label('entry_user')

    query = query.add_columns(branch, document, currency, payment_direction, payment_type, payment_status,
                              contractor, branch2, entry_user, employee)
    return query
