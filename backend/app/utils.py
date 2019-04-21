# coding=utf-8
from copy import copy, deepcopy
import json
from urlparse import urlparse, urljoin
import datetime
import decimal
from dateutil import parser
from flask.ext.wtf import Form
from sqlalchemy import Date
from sqlalchemy.ext.declarative.api import DeclarativeMeta
from wtforms import HiddenField
from flask import redirect, url_for, request, Response, g
import messages

__author__ = 'Ilias'


class JSONEncoderCore(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, datetime.datetime):
            r = str(o)[:19]
            return r
        elif isinstance(o, datetime.date):
            return str(o)
        elif isinstance(o, datetime.time):
            r = str(o)
            return r
        elif isinstance(o, decimal.Decimal):
            return fakefloat(o)
        elif isinstance(o, datetime.timedelta):
            return o.total_seconds()
        elif isinstance(o.__class__, DeclarativeMeta):
            return orm_to_json(o)
        else:
            return super(JSONEncoderCore, self).default(o)


class fakefloat(float):
    def __init__(self, value):
        self._value = value

    def __repr__(self):
        return str(self._value)


def make_json_response(p_content):
    if not p_content:
        p_content = {}
    if 'result' not in p_content:
        p_content.update({'result': 0})

    resp = Response(json.dumps(p_content, cls=JSONEncoderCore), mimetype='application/json; charset=utf-8')
    return resp


class CbsException(Exception):
    def __init__(self, code, message=None):
        super(CbsException, self).__init__()
        self.code = code
        if not message:
            message = messages.MESSAGE.get(code)
        self.message = message


def json_to_orm(json_, orm):
    """
    Merge in items in the values dict into our object if it's one of our columns
    """
    if hasattr(orm, '__table__'):
        for c in orm.__table__.columns:
            if c.name in json_:
                if isinstance(c.type, Date):
                    setattr(orm, c.name, None if not json_[c.name] else parser.parse(json_[c.name]))
                else:
                    setattr(orm, c.name, json_[c.name])
    else:
        for c in orm._asdict().keys():
            if c in json_:
                setattr(orm, c, json_[c])


def orm_to_json(orm):
    if isinstance(orm, list):
        ret = []
        for o in orm:
            if hasattr(o, '__dict__'):
                d = deepcopy(o.__dict__)
            else:
                d = o._asdict()
            d.pop('_sa_instance_state', None)
            ret.append(d)
        return ret
    else:
        if hasattr(orm, '__dict__'):
            d = deepcopy(orm.__dict__)
        else:
            d = orm._asdict()
        d.pop('_sa_instance_state', None)
        return d


class RedirectForm(Form):
    next = HiddenField()

    def __init__(self, *args, **kwargs):
        Form.__init__(self, *args, **kwargs)
        if not self.next.data:
            self.next.data = get_redirect_target() or ''

    def redirect(self, endpoint='index', **values):
        if is_safe_url(self.next.data):
            return redirect(self.next.data)
        target = get_redirect_target()
        return redirect(target or url_for(endpoint, **values))


def is_safe_url(target):
    ref_url = urlparse(request.host_url)
    test_url = urlparse(urljoin(request.host_url, target))
    return test_url.scheme in ('http', 'https') and ref_url.netloc == test_url.netloc


def get_redirect_target():
    for target in request.args.get('next'), request.referrer:
        if not target:
            continue
        if is_safe_url(target):
            return target


def days_in_year(year=datetime.date.today().year):
    d1 = datetime.date(int(year), 1, 1)
    d2 = datetime.date(int(year) + 1, 1, 1)
    return (d2 - d1).days


def string_to_date(date_string, date_format='%Y-%m-%d'):
    if type(date_string) is unicode or type(date_string) is str:
        return datetime.datetime.strptime(date_string, date_format)
    return date_string


def make_hash(o):
    if isinstance(o, (set, tuple, list)):
        return tuple([make_hash(e) for e in o])
    elif not isinstance(o, dict):
        return hash(o)
    new_o = deepcopy(o)
    for k, v in new_o.items():
        new_o[k] = make_hash(v)
    return hash(tuple(frozenset(sorted(new_o.items()))))
