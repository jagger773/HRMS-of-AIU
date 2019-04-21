from flask import g

from app import orm_to_json
from app.controller import data
from app.model import db


def listing(bag):
    ur = None
    table_name = bag["type"]
    table = getattr(db, table_name) if hasattr(db, table_name) else None
    # System dictionary
    if not issubclass(table, db.CouchSync):
        query = g.tran.query(table)
        return {"docs": orm_to_json(query.all()), "count": query.count()}

    return data.listing(bag)
