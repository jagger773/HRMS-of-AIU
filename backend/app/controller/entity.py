from flask import g

import appconf
from app.keys import CRUD, BOBJECT, ID
from app.utils import json_to_orm

__author__ = 'Ilias'


def __get_object(name):
    if not isinstance(name, str):
        return name
    m = __import__('model.db')
    m = getattr(m, 'db')
    m = getattr(m, name)
    return m


def get(bag):
    crud = bag.pop(CRUD)
    m = __get_object(crud)
    o = g.tran.query(m).filter_by(**bag).first()
    return {BOBJECT: o}


def list(bag):
    m = __get_object(bag[CRUD])
    data = g.tran.query(m)
    if 'filter' in bag and bag['filter']:
        data = data.filter_by(**bag['filter'])
    c = data.count()
    if 'order' in bag and bag['order']:
        data = data.order_by(*bag['order'])
    if bag.get('page', ''):
        data = data.offset(int(bag.get('limit', appconf.DEFAULT_PAGE_LIMIT)) * (int(bag['page']) - 1))
    if bag.get('limit', ''):
        data = data.limit(int(bag.get('limit', appconf.DEFAULT_PAGE_LIMIT)))
    data = data.all()
    return {BOBJECT: data, 'count': c}


def add(bag):
    m = __get_object(bag[CRUD])
    id = bag.get(ID, bag[BOBJECT].get(ID, ''))
    if id and int(id) > 0:
        o = g.tran.query(m).filter_by(id=id).first()
        if not o:
            o = m()
    else:
        o = m()
    json_to_orm(bag[BOBJECT], o)
    g.tran.add(o)
    g.tran.flush()
    return o


def remove(bag):
    m = __get_object(bag[CRUD])
    o = g.tran.query(m).filter_by(id=bag[ID]).first()
    g.tran.delete(o)
    g.tran.flush()
    return bag
