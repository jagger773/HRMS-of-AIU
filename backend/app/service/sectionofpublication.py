from app.service import table_access, chain

from app.model import db
from flask import g

from app.utils import orm_to_json


@table_access(name='Sectionsofpublication')
@chain(controller_name='data.listing',  output=['docs'])
def listing(bag):
    pass


@table_access(name='Sectionsofpublication')
@chain(controller_name='data.put', output=['id', 'rev'])
def save(bag):
    pass


@table_access(name='Sectionsofpublication')
@chain(controller_name='data.delete', output=['id', 'rev'])
def remove(bag):
    pass
