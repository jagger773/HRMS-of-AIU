import functools
import json

import datetime
import flask
import werkzeug.exceptions
import werkzeug.http

import appconf
from app.messages import USER_NOT_AUTHORIZED, MESSAGE
from app.storage import PostgresDatabase

pg = flask.Blueprint('couchpg', __name__)


def make_response(code, data):
    def date_handler(obj):
        if hasattr(obj, 'isoformat'):
            return obj.isoformat()
        elif isinstance(obj, datetime.datetime):
            return obj
        elif isinstance(obj, datetime.datetime):
            return obj
        else:
            return None

    resp = flask.make_response(json.dumps(data, default=date_handler))
    resp.status_code = code
    resp.headers['Content-Type'] = 'application/json'
    return resp


def make_error_response(code, error, reason):
    if isinstance(reason, werkzeug.exceptions.HTTPException):
        reason = reason.description
    else:
        reason = str(type(reason) is unicode and reason.encode('utf-8') or reason)
    return make_response(code, {'error': error, 'reason': reason})


def database_should_exists(func):
    @functools.wraps(func)
    def check_db(dbname, *args, **kwargs):
        if dbname != appconf.DB:
            return flask.abort(404, '%s missed' % dbname)
        return func(dbname, *args, **kwargs)

    return check_db


@pg.errorhandler(400)
def bad_request(err):
    return make_error_response(400, 'bad_request', err)


@pg.errorhandler(404)
@pg.errorhandler(PostgresDatabase.NotFound)
def not_found(err):
    return make_error_response(404, 'not_found', err)


@pg.errorhandler(409)
@pg.errorhandler(PostgresDatabase.Conflict)
def conflict(err):
    return make_error_response(409, 'conflict', err)


@pg.errorhandler(412)
def db_exists(err):
    return make_error_response(412, 'db_exists', err)


@pg.before_request
def before():
    if flask.request.method != 'OPTIONS' and not hasattr(flask.g, 'batch') and not hasattr(flask.g, 'user'):
        return make_error_response(401, USER_NOT_AUTHORIZED, MESSAGE[USER_NOT_AUTHORIZED])


@pg.route('/', methods=['GET'])
def index():
    return make_response(200,
                         {'couchdb': 'Postgres-CouchAPI',
                          'vendor': {'name': 'Miller&Weismann', 'version': "1.6.1"},
                          'version': '1.6.1'})


@pg.route('/<dbname>/', methods=['HEAD', 'GET', 'PUT'])
def database(dbname):
    def head():
        return get()

    def get():
        if appconf.DB != dbname:
            return flask.abort(404, '%s missed' % dbname)
        return make_response(200, PostgresDatabase().info())

    def put():
        if dbname == appconf.DB:
            return make_response(201, {'ok': True})
        return flask.abort(400, 'Database creation is disabled')

    return locals()[flask.request.method.lower()]()


@pg.route('/<dbname>/<docid>', methods=['HEAD', 'GET', 'PUT', 'DELETE'])
@database_should_exists
def document(dbname, docid):
    def head():
        return get()

    def get():
        if flask.request.args.get('open_revs'):
            open_revs = json.loads(flask.request.args['open_revs'])
            ret = []
            for rev in open_revs:
                doc = db.load(docid, rev=rev, revs=flask.request.args.get('revs', False))
                ret.append(doc)
            return make_response(200, ret)
        else:
            doc = db.load(docid, rev=flask.request.args.get('rev', None), revs=flask.request.args.get('revs', False))
            return make_response(200, doc)

    def put():
        rev = flask.request.args.get('rev')
        new_edits = json.loads(flask.request.args.get('new_edits', 'true'))

        if flask.request.mimetype == 'application/json':
            doc = flask.request.get_json()

        elif flask.request.mimetype == 'multipart/related':
            parts = parse_multipart_data(
                flask.request.stream, flask.request.mimetype_params['boundary'])

            # CouchDB has an agreement, that document goes before attachments
            # which simplifies processing logic and reduces footprint
            headers, body = next(parts)
            assert headers['Content-Type'] == 'application/json'
            doc = json.loads(body.decode())
            # We have to inject revision into doc there to correct compute
            # revpos field for attachments
            doc.setdefault('_rev', rev)

            for headers, body in parts:
                params = werkzeug.http.parse_options_header(
                    headers['Content-Disposition'])[1]
                fname = params['filename']
                ctype = headers['Content-Type']
                db.add_attachment(doc, fname, body, ctype)

        else:
            # mimics to CouchDB response in case of unsupported mime-type
            return flask.abort(400)

        doc['_id'] = docid

        idx, rev = db.store(doc, rev, new_edits)
        return make_response(201, {'ok': True, 'id': idx, 'rev': rev})

    def delete():
        idx, rev = db.remove(docid, flask.request.args.get('rev', None))
        return make_response(201, {'ok': True, 'id': idx, 'rev': rev})

    db = PostgresDatabase()
    return locals()[flask.request.method.lower()]()


@pg.route('/<dbname>/_design/<docid>', methods=['HEAD', 'GET', 'PUT', 'DELETE'])
def design_document(dbname, docid):
    return document(dbname, '_design/' + docid)


@pg.route('/<dbname>/_local/<docid>', methods=['GET', 'PUT', 'DELETE'])
def local_document(dbname, docid):
    return document(dbname, '_local/' + docid)


@pg.route('/<dbname>/_revs_diff', methods=['POST'])
@database_should_exists
def database_revs_diff(dbname):
    db = PostgresDatabase()
    revs = db.revs_diff(flask.request.json)
    return make_response(200, revs)


@pg.route('/<dbname>/_bulk_docs', methods=['POST'])
@database_should_exists
def database_bulk_docs(dbname):
    db = PostgresDatabase()
    return make_response(201, db.bulk_docs(**flask.request.get_json()))


@pg.route('/<dbname>/_ensure_full_commit', methods=['POST'])
@database_should_exists
def database_ensure_full_commit(dbname):
    db = PostgresDatabase()
    return make_response(201, db.ensure_full_commit())


@pg.route('/<dbname>/_changes', methods=['GET'])
@database_should_exists
def database_changes(dbname):
    args = flask.request.args
    heartbeat = args.get('heartbeat', 10000)
    since = json.loads(args.get('since', '0'))
    feed = args.get('feed', 'normal')
    style = args.get('style', 'all_docs')
    filter = args.get('filter', None)
    limit = args.get('limit', None)
    timeout = int(args.get('timeout', 25000))
    db = PostgresDatabase()
    changes, last_seq = db.changes(since, feed, style, filter, limit, timeout / 1000)
    return make_response(200, {'last_seq': last_seq, 'results': changes})


@pg.route('/<dbname>/_all_docs', methods=['GET', 'POST'])
@database_should_exists
def all_docs(dbname):
    args = {}
    for a in flask.request.args:
        args[a] = json.loads(flask.request.args[a])
    db = PostgresDatabase()
    return make_response(200, db.all_docs(**args))


@pg.route('/<dbname>/_bulk_get', methods=['POST'])
@database_should_exists
def bulk_get(dbname):
    return make_error_response(400, 'bad_request', 'Not supported')


def parse_multipart_data(stream, boundary):
    boundary = boundary.encode()
    next_boundary = boundary and b'--' + boundary or None
    last_boundary = boundary and b'--' + boundary + b'--' or None

    stack = []

    state = 'boundary'
    line = next(stream).rstrip()
    assert line == next_boundary
    for line in stream:
        if line.rstrip() == last_boundary:
            break

        if state == 'boundary':
            state = 'headers'
            if stack:
                headers, body = stack.pop()
                yield headers, b''.join(body)
            stack.append(({}, []))

        if state == 'headers':
            if line == b'\r\n':
                state = 'body'
                continue
            headers = stack[-1][0]
            line = line.decode()
            key, value = map(lambda i: i.strip(), line.split(':'))
            headers[key] = value

        if state == 'body':
            if line.rstrip() == next_boundary:
                state = 'boundary'
                continue
            stack[-1][1].append(line)

    if stack:
        headers, body = stack.pop()
        yield headers, b''.join(body)
