# coding=utf-8

import json
import logging
import sys
import traceback
import os
import urllib
from datetime import timedelta
from time import time
from inspect import isclass
from PIL import Image
from flask import g, request, send_from_directory, flash

from flask import request, g
from flask.ext.cors import CORS
from flask.ext.session import Session
from flask_login import login_required
from flask_mail import Mail
from itsdangerous import URLSafeTimedSerializer
from redis import Redis
from sqlalchemy import DDL, event, and_, desc
from sqlalchemy.orm import make_transient, query

from app import AppFactory, SessionFactory
from app import redis_session
from app.messages import MESSAGE, KEY_ERROR, USER_NOT_AUTHORIZED, GENERIC_ERROR
from app.model import db
from app.model.db import CouchSync, Base, New
from app.pages.peer import pg
from app.service import call
from app.utils import CbsException, make_json_response, orm_to_json
from appconf import DB_URL, REDIS_URI, SECRET_KEY, SECURITY_PASSWORD_SALT
from werkzeug.utils import secure_filename, redirect
from flask.ext.uploads import UploadSet, configure_uploads, IMAGES, DOCUMENTS, ALL, DEFAULTS

import app
from app.controller import entity

from app.keys import BOBJECT, CRUD

sys.path.append('app')

app = AppFactory.create_app(app.__name__)
app.config.from_object('appconf')
app.permanent_session_lifetime = timedelta(minutes=15)
app.config['WTF_CSRF_ENABLED'] = False
app.config['LOGGER_NAME'] = 'st'
app.config['SESSION_COOKIE_NAME'] = 'st'
app.config['SESSION_TYPE'] = 'sqlalchemy'
app.config['SESSION_PERMANENT'] = True
app.config['SESSION_SQLALCHEMY_TABLE'] = 'sessions'
app.config['SQLALCHEMY_DATABASE_URI'] = DB_URL

Session(app)

mail = Mail()
mail.init_app(app)

CORS(app, resources=r'*',
     headers=['Content-Type', 'Authorization', 'Access-Control-Allow-Credentials', 'Access-Control-Allow-Origin'],
     supports_credentials=True)

app.register_blueprint(pg, url_prefix='/sync')

root_dir = os.path.dirname(os.path.abspath(__file__))
static_dir = os.path.join(root_dir, 'app/static')
app.config['UPLOADED_DEFAULTS_DEST'] = os.path.join(static_dir, 'uploads/defaults')
default_uploader = UploadSet('defaults', DEFAULTS)
configure_uploads(app, default_uploader)

@app.route('/')
def index():
    return 'It works'


@app.route('/<string:path>/<string:name>', methods=['GET', 'POST'])
@app.route('/<string:path>.<string:name>', methods=['GET', 'POST'])
def service(path, name):
    if request.endpoint == 'static':
        return
    if request.data:
        bag = json.loads(request.data)
    else:
        bag = {}
    ret = call('{}.{}'.format(path, name), bag)
    return make_json_response(ret)


@app.before_first_request
def before_first():
    app.db = db

    classes = [x for x in dir(db) if isclass(getattr(db, x))]
    for c in classes:
        m = getattr(db, c)
        if issubclass(m, Base) and issubclass(m, CouchSync) and m.__name__ != CouchSync.__name__:
            trigger = DDL(
                """
                CREATE TRIGGER timetravel_{0}
        BEFORE INSERT OR DELETE OR UPDATE ON {0}
        FOR EACH ROW
        EXECUTE PROCEDURE
          timetravel(_created, _deleted);
                """.format(c)
            )
            event.listen(m.__table__, 'after_create', trigger.execute_if(dialect='postgresql'))


@app.before_request
def before():
    g.time = time()
    g.logger = logging.getLogger(request.host)
    g.host = request.host
    g.connection = DB_URL
    g.redis_db = 9
    g.tran = SessionFactory.get_session(db=db, db_string=g.connection, app_name=request.host)
    g.redis = Redis(host=REDIS_URI, db=g.redis_db)

    if 'Authorization' in request.headers and request.authorization:
        auth = request.authorization
        g.token = auth.password
        session = redis_session.get_session(auth.password)
        g.session = session
        if 'user_id' in session:
            g.user = g.tran.query(db.User).filter(db.User.id == session['user_id']).first()
            make_transient(g.user)
    if request.method != 'OPTIONS':
        g.logger.info(u'{0}: Request:{1} - Data:{2}'.format(request.remote_addr, request.url, request.json))


@app.teardown_request
def teardown(exception):
    try:
        if exception is None:
            g.logger.info('{0}: Request:{1} finished in {2} sec'.format(request.remote_addr,
                                                                        request.url,
                                                                        time() - g.time))
            if hasattr(g, 'tran') and g.tran is not None:
                g.tran.commit()
        else:
            g.logger.error(traceback.format_exc())
            if hasattr(g, 'tran') and g.tran is not None:
                g.tran.rollback()
                g.user = None
                g.tran = None
    finally:
        if hasattr(g, 'connection') and g.connection:
            SessionFactory.get_session(db_string=g.connection).remove()


@app.errorhandler(CbsException)
@app.errorhandler(Exception)
def core_error(e):
    g.logger.error(traceback.format_exc())
    try:
        if hasattr(g, 'tran') and g.tran is not None:
            g.tran.rollback()
            g.user = None
            g.tran = None
    finally:
        if hasattr(g, 'connection') and g.connection:
            SessionFactory.get_session(db_string=g.connection).remove()

    if isinstance(e, CbsException):
        msg = e.message if e.message else MESSAGE.get(e.code, 'Got error code: ' + str(e.code))
        return make_json_response({'result': e.code, 'message': msg})
    if isinstance(e, KeyError):
        return make_json_response({'result': KEY_ERROR, 'message': MESSAGE.get(KEY_ERROR, e.message).format(e.message)})
    return make_json_response({'result': -1, 'message': 'Server error'})


@app.route('/upload/<string:path>/<string:id>', methods=['POST'])
def upload_file(path, id):
    directory = os.path.join(os.path.join('app', app.config['UPLOAD_FOLDER'], path), id)
    if 'file' in request.files:
        f = request.files['file']
        if f and allowed_file(f.filename):
            filename = secure_filename(f.filename)
            if not os.path.exists(directory):
                os.makedirs(directory)
            try:
                os.remove(os.path.join(directory, filename))
            except OSError:
                pass
            f.save(os.path.join(directory, filename))
            return '{}/{}/{}'.format(path, id, filename), 200
        return 'File not allowed', 403
    elif request.endpoint == 'static':
        return
    elif request.data:
        bag = json.loads(request.data)
        if 'file' in bag:
            img_data = bag['file'].split(',')[1]
            extension = bag['file'].split(',')[0].split(':')[1].split(';')[0].split('/')[1]
            filename = '{}.{}'.format(int(round(time() * 1000)), extension)
            if allowed_file(filename):
                if not os.path.exists(directory):
                    os.makedirs(directory)
                fh = open(os.path.join(directory, filename), "wb")
                fh.write(img_data.decode('base64'))
                fh.close()
                return make_json_response({'file': '{}/{}/{}'.format(path, id, filename)})
            else:
                return 'File not allowed', 403
    return 'Bad request', 400


@app.route('/upload/docs/file/<string:type>', methods=['POST'])
def upload_zvl_file(type):
    if not hasattr(g, 'user'):
        return MESSAGE.get(USER_NOT_AUTHORIZED), 401
    directory = os.path.join('app', app.config['DOCS_FILE_UPLOAD_FOLDER'], type)
    if 'file' in request.files:
        f = request.files['file']
        if f and allowed_file(f.filename, extensions={'pdf', 'doc', 'docx', 'zip', 'jpg', 'jpeg', 'gif', 'png'}):
            filename = secure_filename(u'{}-{}'.format(g.redis.incr('docs_file_index'), f.filename))
            if not os.path.exists(directory):
                os.makedirs(directory)
            try:
                os.remove(os.path.join(directory, filename))
            except OSError:
                pass
            f.save(os.path.join(directory, filename))
            return u'{}/{}/{}'.format('docs/file', type, filename), 200
        return 'File not allowed', 415
    elif request.endpoint == 'static':
        return
    return 'Bad request', 400


@app.route('/docs/file/<string:type>/<string:name>')
def get_file(type, name):
    filename = secure_filename(urllib.unquote(name))
    path_to_file = os.path.join(app.config['DOCS_FILE_UPLOAD_FOLDER'], type)
    if not os.path.exists(os.path.join('app', path_to_file, filename)):
        return 'Файл не найден', 404
    return send_from_directory(path_to_file, filename)


def allowed_file(filename, extensions=None):
    if extensions is None:
        extensions = {}
    allowed_extensions = {'txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif'}
    if extensions:
        allowed_extensions = extensions
    return '.' in filename and filename.rsplit('.', 1)[1] in allowed_extensions


@app.route('/image/<string:path>/<string:id>/<string:name>', methods=['GET'])
@app.route('/image/<string:path>/<string:id>/<string:name>/<int:width>/<int:height>', methods=['GET'])
def get_image(path, id, name, width=1024, height=1024):
    filename = secure_filename(urllib.unquote(name))
    path_to_file = os.path.join(os.path.join(app.config['UPLOAD_FOLDER'], urllib.unquote(path)), id)
    path_to_thumb = os.path.join(path_to_file, '{}x{}'.format(width, height))
    if not os.path.isfile(os.path.join('app', path_to_file, filename)):
        return 'Image not found', 404
    if not os.path.exists(os.path.join('app', path_to_thumb, filename)):
        img = Image.open(os.path.join('app', path_to_file, filename))
        w, h = img.size
        if w < width and h < height:
            return send_from_directory(path_to_file, filename)
        if not os.path.exists(os.path.join('app', path_to_thumb)):
            os.makedirs(os.path.join('app', path_to_thumb))
        img.thumbnail((width, height))
        img.save(os.path.join('app', path_to_thumb, filename))
    return send_from_directory(path_to_thumb, filename)



@app.route('/regulations_listing', methods=['POST'])
@app.route('/regulations_listing', methods=['GET'])
def regulationsListing():
    query = g.tran.query(db.Regulation)
    regulations = query.all()
    items = []
    for _regulations in regulations:
        item = orm_to_json(_regulations)
        items.append(item)
    return make_json_response({'regulations':items})


@app.route('/questions_and_answers/<string:name>/<string:city>/<string:email>/<string:url>/<string:question>', methods=['POST'])
@app.route('/questions_and_answers/<string:name>/<string:city>/<string:email>/<string:url>/<string:question>', methods=['GET'])
def questions(name,city,email,url,question):
    questions = {}
    questions['name']= name
    questions['city'] = city
    questions['email'] = email
    questions['url'] = url
    questions['question'] = question
    entity.add({CRUD:db.Question, BOBJECT:questions})
    return make_json_response({'questions': questions})


@app.route('/questions_and_answers', methods=['GET'])
def questions_and_answers():
    questions = g.tran.query(db.Question).all()
    return make_json_response({'questions': questions})


@app.route('/get_journals', methods=['GET'])
@app.route('/get_journals', methods=['POST'])
def get():
    journals = g.tran.query(db.Journals).filter_by(_deleted="infinity").all()
    return make_json_response({'journals': journals})


@app.route('/get_articles/<string:journal_id>', methods=['POST'])
@app.route('/get_articles/<string:journal_id>', methods=['GET'])
def getArticles(journal_id):
    articles = g.tran.query(db.Articles).filter_by(journal_id=journal_id).first()
    return make_json_response({'articles':articles})


@app.route('/get_themes', methods=['POST'])
@app.route('/get_themes', methods=['GET'])
def getThemes():
    themes = g.tran.query(db.Themes).filter_by(_deleted="infinity").all()
    return make_json_response({'themes': themes})


@app.route('/confirm/<token>')
def confirm_email(token):
    secret = URLSafeTimedSerializer(SECRET_KEY)
    email = secret.loads(token, salt=SECURITY_PASSWORD_SALT, max_age=3600)
    user = g.tran.query(db.User).filter(db.User.email == email).first()
    if user.confirmed:
        flash('Аккаунт уже подтвержден!')
    else:
        user.confirmed = True
        g.tran.add(user)
        flash('Вы успешно прошли подтверждение аккаунта, спасибо!')

    return {'confirm': orm_to_json(user)}


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=7003, threaded=True)
