from app.service import chain, table_access


@table_access(name='Documents')
@chain(controller_name='data.listing', output=['docs'])
def listing(bag):
    pass


@table_access(name='Documents')
@chain(controller_name='data.put', output=['id', 'rev'])
def save(bag):
    pass
