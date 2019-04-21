# coding=utf-8
import datetime

from flask import g

from sqlalchemy import desc, or_, and_, type_coerce

from app.model import db
from app.utils import orm_to_json
from app import keys


def listing(bag):
    query = g.tran.query(db.Advert)
    if bag.get('name'):
        if bag.get('lang') == 'ru':
            query = query.filter(db.Advert.name_ru.ilike('%' + bag.get('name') + '%'))
        elif bag.get('lang') == 'kg':
            query = query.filter(db.Advert.name_kg.ilike('%' + bag.get('name') + '%'))
    if bag.get('created_from'):
        query = query.filter(db.Advert.created_from >= bag.get('created_from'))
    if bag.get('created_to'):
        query = query.filter(db.Advert.created_to <= bag.get('created_to'))
    if bag.get('is_active'):
        active = bag.get('is_active')
        if active == 'yes':
            query = query.filter_by(is_active=True)
        elif active == 'no':
            query = query.filter_by(is_active=False)
    query = query.order_by(desc(db.Advert.created_from))
    adverts = query.all()
    items = []
    for _adverts in adverts:
        item = orm_to_json(_adverts)
        items.append(item)

    return {'list': items}


def put(bag):
    adverts = g.tran.query(db.Advert).filter_by(id=bag.get('id')).first()
    adverts = adverts if adverts else db.Advert()
    adverts.name_ru = bag.get('name_ru')
    adverts.name_kg = bag.get('name_kg')
    adverts.description_ru = bag.get('description_ru')
    adverts.description_kg = bag.get('description_kg')
    adverts.file = bag.get('file')
    adverts.link = bag.get('link')
    adverts.is_active = bag.get('is_active')
    g.tran.add(adverts)

    return {'adverts': orm_to_json(adverts)}



def remove(bag):
    o = g.tran.query(db.Advert).filter_by(id=bag['id']).first()
    g.tran.delete(o)
    g.tran.flush()
    return



