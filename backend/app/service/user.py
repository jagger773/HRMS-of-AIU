# coding=utf-8
import re
import smtplib
from email.mime.text import MIMEText

import requests
from hashlib import sha1

from datetime import datetime

import sys
from dateutil.parser import parse
import pyotp
from flask import g, app, flash
from flask_login import login_required
from flask_mail import Mail, Message
from itsdangerous import URLSafeTimedSerializer
from sqlalchemy import or_, func, text, desc, asc
from sqlalchemy import type_coerce
from sqlalchemy.dialects.mysql import TEXT
from sqlalchemy.dialects.postgresql import JSONB, json
from sqlalchemy.orm.attributes import InstrumentedAttribute

from run import mail
from app import redis_session, AppFactory
from app.controller import entity
from app.keys import *
from app.messages import *
from app.model import db
from app.service import admin_required, table_access, chain
from app.service import is_admin
from app.utils import CbsException, orm_to_json

from app.keys import PASSWORD

from appconf import SECRET_KEY, SECURITY_PASSWORD_SALT, MAIL_USERNAME

# related company ids in mobile app
COMPANY_IDS = {
    'augarantid': '85c7c7cf-fd1d-4c10-88a3-8931f43c3784'
}

secret = URLSafeTimedSerializer(SECRET_KEY)


def register(bag):
    if 'data' not in bag:
        bag['data'] = {}
    bag['secure'] = pyotp.random_base32()
    bag[PASSWORD] = sha1(bag[PASSWORD] + bag['secure']).hexdigest()

    if not re.match('^[a-zA-Z]+[\w\-_]+$', bag[USERNAME]):
        raise CbsException(GENERIC_ERROR,
                           u'Имя пользователя может содержать только латинские буквы, цифры и знаки "-" и "_"!')

    user = g.tran.query(db.User).filter(db.User.email == bag[EMAIL]).first()
    if user:
        raise CbsException(USER_ALREADY_EXISTS)
    requests.post('https://www.google.com/recaptcha/api/siteverify',
                  data={'secret': '6Ld_ymMUAAAAAD5k8n1rKpzLT0QWBqLrqVq7DLTi',
                        'response': bag.get('g-recaptcha-response')

                        })

    user = entity.add({CRUD: db.User, BOBJECT: bag})

    user_data = {
        ID: user.id,
        EMAIL: user.email,
        'role': user.role,
        'roles_id': user.roles_id,
        'rec_date': user.rec_date,
        'data': user.data
    }

    token = redis_session.open_session({'user_id': user.id})

    email_token = secret.dumps(bag[EMAIL], salt=SECURITY_PASSWORD_SALT)
    recepient = bag[EMAIL]
    send_email(email_token, recepient)

    return {'token': token, 'user': user_data}


def send_email(email_token, recepient):
    html = """<div>
                    <p>Здравствуйте, !</p>
                    <p>Перейдите по этой <a href='https://vak.ictlab.kg:7003/confirm/{}' target=""_blank>{}</a></p>
                </div>""".format(email_token, email_token)
    msg = Message(
        'Подтверждение почты',
        sender=MAIL_USERNAME,
        html=html,
        recipients=[recepient])
    mail.send(msg)
    return


def put(bag):
    user = g.tran.query(db.User).filter_by(id=bag['id']).first()

    if user.email != bag['email']:
        if g.tran.query(db.User).filter_by(email=bag['email']).filter(db.User.id != user.id).count() > 0:
            raise CbsException(GENERIC_ERROR, u'Такой Email зарегистрирован')

    if 'password' in bag:
        password = sha1(bag[PASSWORD].encode('utf-8') + user.secure.encode('utf-8')).hexdigest()
        if bag[PASSWORD] != user.password and password != user.password and is_admin():
            user.password = password
        else:
            CbsException(USER_NO_ACCESS)

    user.email = bag['email']
    user.citizenship_id = bag['citizenship_id'] or None
    user.nationality_id = bag['nationality_id'] or None
    user.birthplace = bag['birthplace'] or None
    user.data = bag['data'] or {}
    user.first_name = bag['first_name']
    user.last_name = bag['last_name']
    user.middle_name = bag['middle_name']
    user.birthday = bag['birthday']
    if 'roles_id' in bag:
        user.roles_id = bag['roles_id']

    user_data = {
        ID: user.id,
        EMAIL: user.email,
        'first_name': user.first_name,
        'last_name': user.last_name,
        'middle_name': user.middle_name,
        'role': user.role,
        'roles_id': user.roles_id,
        'rec_date': user.rec_date,
        'data': user.data,
        'citizenship_id': user.citizenship_id,
        'nationality_id': user.nationality_id,
        'birthplace': user.birthplace,
        'status': user.status
    }
    return {'user': user_data}


def putUsername(bag):
    user = g.tran.query(db.User).filter(db.User.id != g.user.id, db.User.username == bag[USERNAME]).first()
    if user is not None:
        raise CbsException(GENERIC_ERROR, u'Такое имя пользователя уже есть')
    result = re.match('^[a-zA-Z]+[\w\-_]+$', bag[USERNAME])
    if not result:
        raise CbsException(GENERIC_ERROR,
                           u'Имя пользователя может содержать только латинские буквы, цифры и знаки "-" и "_"!')
    user = g.tran.query(db.User).filter_by(id=g.user.id).first()
    password = sha1(bag[PASSWORD].encode('utf-8') + user.secure.encode('utf-8')).hexdigest()
    if password == user.password:
        user.username = bag[USERNAME]
    else:
        raise CbsException(WRONG_PASSWORD)
        return

    user_data = {
        ID: user.id,
        USERNAME: user.username,
        EMAIL: user.email,
        'role': user.role,
        'rec_date': user.rec_date,
        'data': user.data
    }
    return {'user': user_data}


def putPassword(bag):
    user = g.tran.query(db.User).filter_by(id=g.user.id).first()
    password = sha1(bag[PASSWORD].encode('utf-8') + user.secure.encode('utf-8')).hexdigest()
    if password == user.password:
        user.password = sha1(bag["newpswd"] + user.secure).hexdigest()
    else:
        raise CbsException(WRONG_PASSWORD)
        return

    user_data = {
        ID: user.id,
        EMAIL: user.email,
        'role': user.role,
        'rec_date': user.rec_date,
        'data': user.data
    }
    return {'user': user_data}


def putEmail(bag):
    user = g.tran.query(db.User).filter(db.User.id != g.user.id, db.User.email == bag[EMAIL]).first()
    if user is not None:
        CbsException(GENERIC_ERROR, u'Такой E-mail уже есть')

    user = g.tran.query(db.User).filter_by(id=g.user.id).first()
    password = sha1(bag[PASSWORD].encode('utf-8') + user.secure.encode('utf-8')).hexdigest()
    if password == user.password:
        user.email = bag[EMAIL]
    else:
        raise CbsException(WRONG_PASSWORD)
        return

    user_data = {
        ID: user.id,
        EMAIL: user.email,
        'role': user.role,
        'rec_date': user.rec_date,
        'data': user.data
    }
    return {'user': user_data}


def secure(bag):
    user = g.tran.query(db.User).filter_by(id=bag['id']).first()
    password = sha1(bag[PASSWORD].encode('utf-8') + user.secure.encode('utf-8')).hexdigest()
    if password == user.password:
        user.password = sha1(bag["new_password"] + user.secure).hexdigest()
    else:
        raise CbsException(WRONG_PASSWORD)

    user_data = {
        ID: user.id,
        EMAIL: user.email,
        'role': user.role,
        'rec_date': user.rec_date,
        'data': user.data
    }
    return {'user': user_data}


def auth(bag):
    user = g.tran.query(db.User).filter(db.User.email == bag[EMAIL]).first()
    if not user:
        raise CbsException(USER_NOT_FOUND)
    password = sha1(bag[PASSWORD].encode('utf-8') + user.secure.encode('utf-8')).hexdigest()
    if user.password != password:
        raise CbsException(WRONG_PASSWORD)

    user_data = {
        ID: user.id,
        EMAIL: user.email,
        'first_name': user.first_name,
        'last_name': user.last_name,
        'middle_name': user.middle_name,
        'role': user.role,
        'roles_id': user.roles_id,
        'rec_date': user.rec_date,
        'data': user.data
    }

    token = redis_session.open_session({'user_id': user.id})

    return {'token': token, 'user': user_data}


def listing(bag):
    query = g.tran.query(db.User.id).select_from(db.User)
    if "filter" in bag:
        if 'filter' in bag and 'first_name' in bag['filter']:
            query = query.filter(db.User.first_name.ilike(u"%{}%".format(bag["filter"]["first_name"])))
            del bag["filter"]["first_name"]
        if 'filter' in bag and 'last_name' in bag['filter']:
            query = query.filter(db.User.last_name.ilike(u"%{}%".format(bag["filter"]["last_name"])))
            del bag["filter"]["last_name"]
        if 'filter' in bag and 'middle_name' in bag['filter']:
            query = query.filter(db.User.middle_name.ilike(u"%{}%".format(bag["filter"]["middle_name"])))
            del bag["filter"]["middle_name"]
        query = query.filter_by(**bag["filter"])
    doc_vars = vars(db.User)
    for var in doc_vars:
        if var != 'password' and var != 'secure' and isinstance(doc_vars[var], InstrumentedAttribute):
            query = query.add_column(doc_vars[var])
    query = query.order_by(asc(db.User.id))
    count = query.count()
    if "limit" in bag:
        query = query.limit(bag["limit"])
    if "offset" in bag:
        query = query.offset(bag["offset"])

    return {'users': orm_to_json(query.all()), 'count': count}


def get(bag):
    query = g.tran.query(db.User).filter_by(id=bag['id']).one()
    query = orm_to_json(query)
    query['citizenship'] = {}
    query['nationality'] = {}
    query['citizenship'] = g.tran.query(db.Citizenship).filter_by(_deleted='infinity',
                                                                  _id=query['citizenship_id']).first()
    query['nationality'] = g.tran.query(db.Nationality).filter_by(_deleted='infinity',
                                                                  _id=query['nationality_id']).first()
    return {'user': query}


# def putusers(bag):
#     for item in bag['items']:
#         if 'data' not in item:
#             item['data'] = {}
#         item['birthday'] = datetime.strptime(item['birthday'], '%d.%m.%Y')
#         item['secure'] = pyotp.random_base32()
#         item['password'] = sha1(item['password'] + item['secure']).hexdigest()
#
#         if not re.match('^[a-zA-Z]+[\w\-_]+$', item['username']):
#             print item
#             raise CbsException(GENERIC_ERROR,
#                                u'Имя пользователя может содержать только латинские буквы, цифры и знаки "-" и "_"!')
#
#         user = g.tran.query(db.User).filter(db.User.username == item['username']).first()
#         if user:
#             print item
#             raise CbsException(USER_ALREADY_EXISTS)
#         user = entity.add({CRUD: db.User, BOBJECT: item})
#     return
