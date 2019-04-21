from datetime import datetime
from flask import g

from app.model import db
from app.service import chain, table_access
from app import controller


@table_access(name='Countries')
@chain(controller_name='data.listing', output=['docs'])
def listing(bag):
    pass


@table_access(name='Countries')
@chain(controller_name='data.put', output=['id', 'rev'])
def save(bag):
    pass


def save_dict(bag):
    degrees = g.tran.query(db.Academicdegree).filter_by(_deleted='infinity').all()
    actiontypes = g.tran.query(db.Actiontype).filter_by(_deleted='infinity').all()
    attestation_departments = g.tran.query(db.Attestation_department).filter_by(_deleted='infinity').all()
    documenttypes = g.tran.query(db.Documenttype).filter_by(_deleted='infinity').all()
    users = g.tran.query(db.User).all()
    for item in bag['data']:
        item['type'] = 'Userdegree'
        item['action_date'] = datetime.strptime(item['action_date'], '%d.%m.%Y')
        for documenttype in documenttypes:
            if item['document_type'] == documenttype.name_ru:
                item['documenttype_id'] = documenttype._id
        for degree in degrees:
            if item['degree'] == degree.name_ru:
                item['academicdegree_id'] = degree._id
        for actiontype in actiontypes:
            if item['action_type'] == actiontype.name_ru:
                item['actiontype_id'] = actiontype._id
        for attestation_department in attestation_departments:
            if item['attestation_department'] == attestation_department.name_ru:
                item['attestation_department_id'] = attestation_department._id
        for user in users:
            if item['user_id'] == user.id:
                item['user_id'] = user.id
        controller.call(controller_name='data.put', bag=item)
    return


def save_spec(bag):
    userdegrees = g.tran.query(db.Userdegree).filter_by(_deleted='infinity').all()
    specialities = g.tran.query(db.Specialty).filter_by(_deleted='infinity').all()
    for item in bag['data']:
        item['type'] = 'Degreespeciality'
        item['type'] = 'Degreespeciality'
        for userdegree in userdegrees:
            if item['document_code'] == userdegree.document_code:
                item['userdegree_id'] = userdegree._id
        for spec in specialities:
            if item['code'] == spec.code:
                item['specialty_id'] = spec._id
        controller.call(controller_name='data.put', bag=item)
    return
