from app.service import table_access, chain


@table_access('Journals')
@chain(controller_name='data.listing', output=['docs'])
def listing(bag):
    pass


@table_access('Journals')
@chain(controller_name='data.put', output=["id", "rev"])
def save(bag):
    pass
