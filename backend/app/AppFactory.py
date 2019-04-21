import logging
import logging.handlers

from flask import Flask



__author__ = 'Ilias'


def create_app(name, logger_name='daily.log', test=False):
    if not test:
        try:
            logging.basicConfig(level=logging.INFO,
                                format="%(threadName)s %(asctime)s %(name)-12s %(message)s",
                                datefmt="%d-%m-%y %H:%M")

            daily = logging.handlers.TimedRotatingFileHandler("log/" + logger_name, when="midnight", interval=1,
                                                              backupCount=15,
                                                              encoding="utf-8")
            logging.getLogger().addHandler(daily)
            fmt = logging.Formatter('%(asctime)s %(name)-12s %(message)s')
            daily.setFormatter(fmt)
            daily.setLevel(logging.DEBUG)
        except:
            pass

    app = Flask(name)
    return app


