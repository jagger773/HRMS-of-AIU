# -*- coding: utf-8 -*-
from flask import g

from app import controller
from app.model import db
from app.service import table_access, chain


@table_access(name='Dcomposition')
@chain(controller_name='data.listing', output=['docs'])
def listing(bag):
    pass


