# coding=utf-8
from functools import update_wrapper

from flask import g, request

from app import controller
from app.messages import USER_NOT_AUTHORIZED, USER_NO_ACCESS
from app.utils import CbsException


def chain(service_name='', controller_name='', output=None):
    def decorator(fn):
        def wrapper_function(bag):
            if service_name:
                bag.update(call(service_name, bag))
            elif controller_name:
                bag.update(controller.call(controller_name, bag))
            if not output:
                return fn(bag)
            res = fn(bag)
            if res is dict:
                bag.update(res)
            ret = {}
            for k in output:
                ret[k] = bag[k]
            return ret

        return update_wrapper(wrapper_function, fn)

    return decorator


def table_access(name='', names=None):
    def decorator(fn):
        def wrapper_function(bag):
            if name:
                bag['type'] = name
            if names:
                assert bag['type'] in names
            return fn(bag)

        return update_wrapper(wrapper_function, fn)

    return decorator


def auth_required():
    def decorator(fn):
        def wrapped_function(*args, **kwargs):
            # Only for not authenticated users.
            if hasattr(g, 'batch') or hasattr(g, 'user') or request.path in ['/user/auth',
                                                                             '/user/register',
                                                                             '/user/listing',
                                                                             '/questions/put',
                                                                             'user/putusers',
                                                                             '/adverts/listing',
                                                                             '/news/mainlisting',
                                                                             '/news/listing',
                                                                             '/sectionofpublication/listing',
                                                                             '/questions/put_question',
                                                                             '/questions/listing',
                                                                             '/regulations/listing',
                                                                             '/departments/listing',
                                                                             '/dissov/listing',
                                                                             '/banners/listing']:
                return fn(*args, **kwargs)
            raise CbsException(USER_NOT_AUTHORIZED)

        return update_wrapper(wrapped_function, fn)

    return decorator


def admin_required():
    def decorator(fn):
        def wrapped_function(*args, **kwargs):
            # Only for not authenticated users.
            if not hasattr(g, 'user') or not g.user:
                raise CbsException(USER_NOT_AUTHORIZED)
            if g.user.role < 10:
                raise CbsException(USER_NO_ACCESS)
            return fn(*args, **kwargs)

        return update_wrapper(wrapped_function, fn)

    return decorator


def is_admin():
    return g.user.role >= 10


@auth_required()
def call(service_name, bag):
    if hasattr(service_name, '__call__'):
        return service_name(bag)
    module = service_name.split('.')
    m = __import__('service.' + module[0])
    m = getattr(m, module[0])
    m = getattr(m, module[1])
    return m(bag)
