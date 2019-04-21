from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, scoped_session

__author__ = 'Ilias'


def build_session(db=None, url=None, app_name=''):
    global DB_SESSION
    global DB_ENGINE
    global TEST
    if "DB_SESSION" not in globals():
        DB_ENGINE = {}
        DB_SESSION = {}

    if url in DB_SESSION:
        return
    pool_size = 20
    DB_ENGINE[url] = create_engine(url, pool_size=pool_size, connect_args={'application_name': app_name})
    DB_SESSION[url] = scoped_session(sessionmaker(bind=DB_ENGINE[url], autoflush=True))
    if db:
        db.Base.metadata.create_all(DB_ENGINE[url])


def get_engine(db=None, db_string=None, app_name=''):
    build_session(db, db_string, app_name)
    return DB_ENGINE[db_string]


def get_session(db=None, db_string=None, app_name=''):
    build_session(db, db_string, app_name)
    return DB_SESSION[db_string]
