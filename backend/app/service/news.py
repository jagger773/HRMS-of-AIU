# coding=utf-8
import datetime

from flask import g

from sqlalchemy import desc, or_, and_, type_coerce, asc

from app.model import db
from app.utils import orm_to_json
from app import keys,controller
from app.service import table_access, chain
from sqlalchemy.dialects.mysql import TEXT


def mainlisting(bag):
    query = g.tran.query(db.New).filter_by(_deleted='infinity')\
        .filter(db.New.is_active == True)
    query.section = None
    if bag.get('name'):
        if bag.get('lang') == 'ru':
            query = query.filter(db.New.name_ru.ilike('%' + bag.get('name') + '%'))
        elif bag.get('lang') == 'kg':
            query = query.filter(db.New.name_kg.ilike('%' + bag.get('name') + '%'))
    if bag.get('created_from'):
        query = query.filter(db.New.created_from >= bag.get('created_from'))
    if bag.get('created_to'):
        query = query.filter(db.New.created_to <= bag.get('created_to'))
    if bag.get('is_active'):
        active = bag.get('is_active')
        if active == 'yes':
            query = query.filter_by(is_active=True)
        elif active == 'no':
            query = query.filter_by(is_active=False)

    section = g.tran.query(db.Sectionsofpublication.name_ru) \
        .select_from(db.Sectionsofpublication) \
        .filter_by(_deleted='infinity').filter(
        db.Sectionsofpublication._id == db.New.sectionsofpublication_id).as_scalar() \
        .label('section')

    query = query.add_columns(section)
    query = query.order_by(db.New.created_from.desc())
    query = query.limit(10).all()
    return {'docs': orm_to_json(query)}


@table_access('New')
@chain(controller_name='data.listing', output=['docs'])
def listing(bag):
    pass


@table_access(name='New')
@chain(controller_name='data.put', output=['id', 'rev'])
def put(bag):
    pass


@table_access('New')
@chain(controller_name='data.remove', output=["ok", "id", "rev"])
def delete(bag):
    pass
