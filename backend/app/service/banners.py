from app.service import chain, table_access


@table_access(name='Banners')
@chain(controller_name='data.listing', output=['docs'])
def listing(bag):
    pass


@table_access(name='Banners')
@chain(controller_name='data.put', output=['ok'])
def put(bag):
    pass


@table_access(name='Banners')
@chain(controller_name='data.remove', output=['ok'])
def remove(bag):
    pass
