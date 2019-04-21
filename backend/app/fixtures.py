from inspect import isclass
import logging
from factory.alchemy import SQLAlchemyModelFactory
from sqlalchemy.exc import IntegrityError

__author__ = 'Ilias'


def create_all(cls, session):
    classes = [x for x in dir(cls) if isclass(getattr(cls, x))]
    for c in classes:
        m = getattr(cls, c)
        if issubclass(m, FixtureBase) and m.__name__ != FixtureBase.__name__:
            m(session).create()


class FixtureBase():
    model_for = None
    session = None

    def __getitem__(self, item, col='id'):
        return getattr(self, item)._declarations[col]

    def __init__(self, model_for=None, session=None):
        self.model_for = model_for
        self.session = session

    def create(self):
        classes = [x for x in dir(self) if isclass(getattr(self, x))]
        for c in classes:
            m = getattr(self, c)
            if issubclass(m, SQLAlchemyModelFactory) and m.__name__ != SQLAlchemyModelFactory.__name__:
                m._meta.sqlalchemy_session = self.session
                try:
                    m.create()
                    self.session.commit()
                except IntegrityError as e:
                    self.session.rollback()
                    logging.info(e.message)
