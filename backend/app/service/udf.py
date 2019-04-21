from app.service import table_access, chain


@table_access('UDF')
@chain(controller_name='data.listing', output=['docs', 'count'])
def list(bag):
    pass


@table_access('UDF')
@chain(controller_name='data.put', output=['id', 'rev'])
def save(bag):
    pass
