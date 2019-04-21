# -*- coding: utf-8 -*-
import datetime

from app.service import chain, table_access
from flask import g

from sqlalchemy import desc, or_, and_, type_coerce

from app import controller
from app.service import table_access, chain
from app.model import db
from app.utils import orm_to_json


@table_access(name='Application')
@chain(controller_name='data.listing', output=['docs'])
def listing(bag):
    pass


@table_access(name='Application')
def save(bag):
    bag["user_id"] = g.user.id
    bag["status"] = u"Новый "
    controller.call(controller_name='data.put', bag=bag)
    return


@table_access('Application')
@chain(controller_name='data.remove', output=["ok", "id", "rev"])
def delete(bag):
    pass


@table_access('Application')
@chain(controller_name='data.get', output=['doc'])
def get(bag):
    pass
