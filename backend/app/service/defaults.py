from app.model import db
from app.service import table_access, chain


@table_access(name=db.DocumentDefaults.__name__)
@chain(controller_name='data.listing', output=['docs'])
def list(bag):
    pass


@table_access(name=db.DocumentDefaults.__name__)
@chain(controller_name='data.put', output=['id', 'rev'])
def save(bag):
    pass
