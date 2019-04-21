from app.service import chain, table_access
from app import controller


@table_access(name='Queue')
@chain(controller_name='data.listing', output=['docs'])
def listing(bag):
    pass


@table_access(name='Queue')
@chain(controller_name='data.put', output=['id', 'rev'])
def save(bag):
    pass


@table_access('Queue')
@chain(controller_name='data.remove', output=["ok", "id", "rev"])
def delete(bag):
    pass


@table_access('Queue')
@chain(controller_name='data.get', output=['doc'])
def get(bag):
    pass
