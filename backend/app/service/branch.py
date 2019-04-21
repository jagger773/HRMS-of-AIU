
# -*- coding: utf-8 -*-
import datetime

from sqlalchemy import or_, type_coerce, func
from flask import g
from sqlalchemy import or_, type_coerce
from sqlalchemy.dialects.postgresql import JSONB
from datetime import datetime

from app.keys import *
from app.messages import *
from app.model import db
from app.service import table_access, chain
from app.utils import CbsException, orm_to_json


def find(bag):
    sql = g.tran.query(db.Branchesofscience)
    if bag.get('id'):
        sql = sql.filter(db.Branchesofscience._id == bag['id'])
    elif bag.get('search'):
        search = bag['search'] if bag.get('search') else ''
        sql = sql.filter(or_(func.concat(db.Branchesofscience.name_ru, ' ', db.Branchesofscience.code, ' ')).ilike(u"%{0}%".format(search)))

    return {'docs': sql.limit(str(bag.get('limit', 30))).all()}
