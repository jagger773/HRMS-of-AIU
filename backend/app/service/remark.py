# -*- coding: utf-8 -*-
from flask import g

from app import controller
from app.model import db
from app.service import table_access, chain


@table_access(name='DisRemarks')
@chain(controller_name='data.listing', output=['docs'])
def listing(bag):
    pass


@table_access(name='DisRemarks')
@chain(controller_name='data.put', output=["id", "rev"])
def save(bag):
    pass


@table_access('DisRemarks')
@chain(controller_name='data.remove', output=["ok", "id", "rev"])
def delete(bag):
    pass


@table_access('DisRemarks')
@chain(controller_name='data.get', output=['doc'])
def get(bag):
    pass

