# coding=utf-8
import os
from app.keys import BOBJECT
from app.service import chain, table_access
from app import controller, CbsException, GENERIC_ERROR
from run import app


@table_access(name='Education')
@chain(controller_name='data.listing', output=['docs'])
def listing(bag):
    pass


@table_access(name='Education')
@chain(controller_name='data.put', output=['id', 'rev'])
def save(bag):
    pass


def file_size(bag):
    filename = bag[BOBJECT]
    path_to_file = os.path.join(app.root_path, app.config['UPLOAD_FOLDER'], filename)
    if not os.path.isfile(path_to_file):
        raise CbsException(GENERIC_ERROR, u'Файл не найден')
    size = os.path.getsize(path_to_file)
    return {BOBJECT: size}


@table_access('Education')
@chain(controller_name='data.remove', output=["ok", "id", "rev"])
def delete(bag):
    pass
