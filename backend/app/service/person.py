# -*- coding: utf-8 -*-
from flask import g
from app.model import db
from sqlalchemy import or_, func

__author__ = 'admin'


def find(bag):
    sql = g.tran.query(db.User)
    if bag.get('id'):
        sql = sql.filter(db.User.id == bag['id'])
    elif bag.get('search'):
        search = bag['search'] if bag.get('search') else ''
        sql = sql.filter(or_(func.concat(db.User.last_name, ' ', db.User.first_name, ' ').ilike(u"%{0}%".format(search))))
    return {'docs': sql.limit(str(bag.get('limit', 30))).all()}
