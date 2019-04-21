# -*- coding: utf-8 -*-
from flask import g

from app import controller
from app.model import db
from app.service import table_access, chain
from app.utils import CbsException, orm_to_json
from app.keys import *
from app.messages import *


@table_access(name='DisApplication')
@chain(controller_name='data.listing', output=['docs'])
def listing(bag):
    pass


@table_access(name='DisApplication')
def save(bag):
    bag["user_id"] = g.user.id
    document = g.tran.query(db.Documents)\
        .filter_by(_deleted='infinity')\
        .filter(db.Documents.theme_id == bag["theme_id"]).first()
    bag["document_id"] = document._id
    bag["status"] = 'new'
    controller.call(controller_name='data.put', bag=bag)
    return


@table_access('DisApplication')
@chain(controller_name='data.remove', output=["ok", "id", "rev"])
def delete(bag):
    pass


@table_access('DisApplication')
@chain(controller_name='data.get', output=['doc'])
def get(bag):
    pass


@table_access('DisApplication')
def update(bag):
    remark = g.tran.query(db.DisRemarks).filter_by(_deleted='infinity')\
        .filter(db.DisRemarks.dissov_id == bag["dissov_id"],
                db.DisRemarks.document_id == bag["document_id"],
                db.DisRemarks.disapp_status == bag["status"],
                db.DisRemarks.status == 'new').first()
    if remark:
        raise CbsException(GENERIC_ERROR, u'Не исправлено замечание')
    controller.call(controller_name='data.put', bag=bag)
