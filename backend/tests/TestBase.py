import json
import logging
import traceback
import unittest
from random import randint

from flask import g, request

from app import AppFactory, model
from app import SessionFactory
from app import fixtures
from app import service
from app.utils import make_json_response, JSONEncoderCore

__author__ = 'Ilias'

app = AppFactory.create_app('backend', test=True)


@app.teardown_request
def teardown(exception):
    g.tran.commit()


@app.errorhandler(Exception)
def error(e):
    logging.error(traceback.format_exc())
    try:
        g.tran.rollback()
    finally:
        SessionFactory.get_session().remove()


@app.route('/<string:path>/<string:name>', methods=['GET', 'POST'])
@app.route('/<string:path>.<string:name>', methods=['GET', 'POST'])
def index(path, name):
    if request.endpoint == 'static':
        return
    if request.data:
        bag = json.loads(request.data)
    else:
        bag = {}
    ret = service.call('{}.{}'.format(path, name), bag)
    return make_json_response(ret)


class TestBase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        super(TestBase, cls).setUpClass()
        cls.client = app.test_client()
        cls.session = SessionFactory.get_session()
        fixtures.create_all(model, cls.session)
        cls.session.commit()

    def post_in_context(self, url, args, has_user=True, user_id=1):
        with app.app_context():
            g.tran = self.session()
            g.redis = reddi()
            g.test = True
            ret = self.client.post(url, data=json.dumps(args, cls=JSONEncoderCore),
                                   headers={'Content-Type': 'application/json'})
            self.assertEqual(200, ret.status_code)
            return json.loads(ret.data)

    def run_job(self, name, args):
        with app.app_context():
            g.tran = self.session()
            g.redis = reddi()
            return name(args)

    @classmethod
    def tearDownClass(cls):
        super(TestBase, cls).tearDownClass()


class reddi():
    data = {
    }

    def incr(self, id):
        return randint(1, 100000)

    def get(self, name):
        return self.data.get(name, None)

    def setex(self, id, val, time):
        self.data[id] = val

    def set(self, id, val):
        self.data[id] = val

    def delete(self, names):
        del self.data[names]
