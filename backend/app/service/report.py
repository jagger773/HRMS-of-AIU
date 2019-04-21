import json
from flask import g

from sqlalchemy import desc, or_, and_, type_coerce
from sqlalchemy.dialects.postgresql import JSONB

from app.model import db
from app.service import chain, table_access


@table_access(db.DirReportTemplates.__name__)
@chain(controller_name='data.get')
def get(bag):
    return {'report': bag['doc']}


@table_access(db.DirReportTemplates.__name__)
@chain(controller_name='data.listing')
def listing(bag):
    return {'report_list': bag['docs'], 'count': bag['count']}


@table_access(db.DirReportTemplates.__name__)
@chain(controller_name='data.put', output=['id', 'rev'])
def put(bag):
    pass


@table_access(db.DirReportQueries.__name__)
@chain(controller_name='data.get', output=['doc'])
def query_get(bag):
    pass


@table_access(db.DirReportQueries.__name__)
@chain(controller_name='data.listing', output=['docs', 'count'])
def query_listing(bag):
    pass


@table_access(db.DirReportQueries.__name__)
@chain(controller_name='data.put', output=['id', 'rev'])
def query_put(bag):
    pass


@table_access(db.DirReportCategories.__name__)
@chain(controller_name='data.listing', output=['docs', 'count'])
def category_listing(bag):
    pass


def get_query_result(bag):
    result = {}
    _args = dict(bag.get('parameters') or {})
    sql = g.tran.query(db.DirReportQueries).filter_by(_deleted='infinity')
    if g.company.company_type == 'agent':
        insurance_company = g.tran.query(db.Companies).filter_by(_deleted='infinity') \
            .filter(db.Companies.agents_id.contains(type_coerce([g.company._id], JSONB))).first()
        _args['company_id'] = insurance_company._id
    else:
        _args['company_id'] = g.company._id
    params = json.dumps(_args)
    queries = sql.filter(db.DirReportQueries.code == bag.get('code')).all()
    for query in queries:
        query_str = query.query.format(params=params)
        rows = g.tran.execute(query_str).fetchall()
        result[query.result_key] = []
        for row in rows:
            result[query.result_key].append(dict(row.items()))
    return {'data': result}


