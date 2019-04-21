# coding=utf-8
import datetime

from flask import g

from sqlalchemy import desc, or_, and_, type_coerce

from app.model import db
from app.utils import orm_to_json
from app import keys,controller


def listing(bag):
    query = g.tran.query(db.Regulation)
    if bag.get('name'):
        if bag.get('lang') == 'ru':
            query = query.filter(db.Regulation.name_ru.ilike('%' + bag.get('name') + '%'))
        elif bag.get('lang') == 'kg':
            query = query.filter(db.Regulation.name_kg.ilike('%' + bag.get('name') + '%'))
    if bag.get('departmentdocument_id'):
        query = query.filter(db.Regulation.departmentdocument_id == bag.get('departmentdocument_id'))
    if bag.get('created_from'):
        query = query.filter(db.Regulation.created_from >= bag.get('created_from'))
    if bag.get('created_to'):
        query = query.filter(db.Regulation.created_to <= bag.get('created_to'))
    query = query.order_by(desc(db.Regulation.created_from))
    regulations = query.all()
    items = []
    for _regulations in regulations:
        item = orm_to_json(_regulations)
        items.append(item)

    return {'list': items}


def put(bag):
    regulations = g.tran.query(db.Regulation).filter_by(id=bag.get('id')).first()
    regulations = regulations if regulations else db.Regulation()
    regulations.departmentdocument_id = bag.get('departmentdocument_id')
    regulations.name_ru = bag.get('name_ru')
    regulations.name_kg = bag.get('name_kg')
    regulations.file = bag.get('file')
    g.tran.add(regulations)

    return {'regulations': orm_to_json(regulations)}




def remove(bag):
    o = g.tran.query(db.Regulation).filter_by(id=bag['id']).first()
    g.tran.delete(o)
    g.tran.flush()
    return




