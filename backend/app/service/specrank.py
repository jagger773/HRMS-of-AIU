# -*- coding: utf-8 -*-
import datetime

from app.service import chain, table_access
from flask import g

from sqlalchemy import desc, or_, and_, type_coerce

from app import controller
from app.service import table_access, chain
from app.model import db
from app.utils import orm_to_json
from sqlalchemy import or_, type_coerce, func

__author__ = 'admin'


def find(bag):
    sql = g.tran.query(db.Specialtyrank)
    if bag.get('id'):
        sql = sql.filter(db.Specialtyrank._id == bag['id'])
    elif bag.get('search'):
        search = bag['search'] if bag.get('search') else ''
        sql = sql.filter(db.Specialtyrank.name_ru.ilike(u"%{}%".format(search)))

    return {'docs': sql.limit(str(bag.get('limit', 30))).all()}
