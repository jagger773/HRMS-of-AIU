from app.service import chain, table_access
from app import controller


@table_access(name='Userrank')
@chain(controller_name='data.listing', output=['docs'])
def listing(bag):
    pass


@table_access(name='Userrank')
@chain(controller_name='data.put', output=['id', 'rev'])
def save(bag):
    pass


@table_access('Userrank')
@chain(controller_name='data.remove', output=["ok", "id", "rev"])
def delete(bag):
    pass
