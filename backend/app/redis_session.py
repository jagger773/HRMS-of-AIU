import json
from datetime import timedelta
from uuid import uuid1

from flask import g

from app import CbsException, messages

SESSION_TIMEOUT = 30


def open_session(data):
    sid = str(uuid1(clock_seq=g.redis.incr('session_id')))
    g.redis.setex('session:' + sid, json.dumps(data), timedelta(minutes=SESSION_TIMEOUT))
    return sid


def update_session(token, data):
    session = get_session(token)
    if not session:
        raise CbsException(messages.USER_NOT_AUTHORIZED)
    session.update(data)
    g.redis.setex('session:' + token, json.dumps(session), timedelta(minutes=SESSION_TIMEOUT))


def get_session(token):
    data = g.redis.get('session:' + token)
    if data:
        g.redis.setex('session:' + token, data, timedelta(minutes=SESSION_TIMEOUT))
        return json.loads(data)
    return {}
