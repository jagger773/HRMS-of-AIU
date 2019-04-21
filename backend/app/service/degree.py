# coding=utf-8
from array import array

from flask import g
from sqlalchemy import func
from sqlalchemy import text
from sqlalchemy import TEXT
from sqlalchemy import cast
from sqlalchemy import type_coerce
from sqlalchemy.orm.attributes import InstrumentedAttribute

from app.model import db
from app.service import chain, table_access
from app.utils import orm_to_json


@table_access(name='Userdegree')
@chain(controller_name='data.listing', output=['docs'])
def listing(bag):
    pass


@table_access(name='Userdegree')
@chain(controller_name='data.put', output=['id', 'rev'])
def save(bag):
    pass


@table_access('Userdegree')
@chain(controller_name='data.remove', output=["ok", "id", "rev"])
def delete(bag):
    pass


@table_access('Userdegree')
@chain(controller_name='data.get', output=['doc'])
def get(bag):
    pass


def get(self, bag):
    query = g.tran.query(db.Companies) \
        .filter_by(_deleted='infinity', _id=bag['id'])
    doc_vars = vars(db.Companies)
    for var in doc_vars:
        if isinstance(doc_vars[var], InstrumentedAttribute):
            query = query.add_column(doc_vars[var])

    if 'with_related' in bag and bag['with_related'] is True:
        company_status_value = g.tran.query(
            func.row_to_json(text('enums.*'))).select_from(db.Enums) \
            .filter_by(_deleted='infinity', name='company_status') \
            .filter(db.Enums.data['key'].cast(TEXT) == cast(db.Companies.company_status, TEXT)) \
            .as_scalar().label('company_status_value')

        company_type_value = g.tran.query(
            func.row_to_json(text('enums.*'))).select_from(db.Enums) \
            .filter_by(_deleted='infinity', name='company_type') \
            .filter(db.Enums.data['key'].cast(TEXT) == cast(db.Companies.company_type, TEXT)) \
            .as_scalar().label('company_type_value')

        entry_user = g.tran.query(func.json_build_object(
            "id", db.User.id, "username", db.User.username, "email", db.User.email, "rec_date", db.User.rec_date,
            "data", db.User.data, "role", db.User.role)).select_from(db.User).filter_by(
            id=db.Companies.entry_user_id) \
            .as_scalar().label('entry_user')

        typeofownership = g.tran.query(func.row_to_json(text('typeofownership.*'))).select_from(db.Typeofownership) \
            .filter_by(_deleted='infinity', _id=db.Companies.typeofownership_id).as_scalar() \
            .label('typeofownership')

        dircountry = g.tran.query(func.row_to_json(text('dircountry.*'))).select_from(db.DirCountry) \
            .filter_by(_deleted='infinity', _id=db.Companies.dircountry_id).as_scalar() \
            .label('dircountry')

        dircoate = g.tran.query(func.row_to_json(text('dircoate.*'))).select_from(db.DirCoate) \
            .filter_by(_deleted='infinity', _id=db.Companies.dircoate_id).as_scalar() \
            .label('dircoate')

        roles = g.tran.query(func.jsonb_agg(func.row_to_json(text('roles.*')))).select_from(db.Roles) \
            .filter_by(_deleted='infinity') \
            .filter(type_coerce(db.Companies.roles_id).has_any(array([db.Roles._id]))) \
            .as_scalar().label('roles')

        company_users = g.tran.query(db.Companyemployees.user_id).filter_by(_deleted='infinity',
                                                                            company_id=bag['id']).all()
        company_users = []
        for user_id in company_users:
            user = g.tran.query(func.json_build_object(
                "id", db.User.id, "username", db.User.username, "email", db.User.email, "rec_date", db.User.rec_date,
                "data", db.User.data, "role", db.User.role)).select_from(db.User) \
                .filter_by(id=user_id).first()
            company_users.append(user)

        query = query.add_columns(company_status_value, company_type_value, entry_user, company_users, typeofownership,
                                  dircountry, roles, dircoate)

    company = query.one()
    return {'doc': orm_to_json(company)}
