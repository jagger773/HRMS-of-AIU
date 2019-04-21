#main config

SECRET_KEY = '4fc5b9d2593d5d7'
SECURITY_PASSWORD_SALT = 'email-confirm'
DB = 'vak_test'
LICENSE_DB_URI = 'postgresql://postgres:ictlab2017@176.126.166.21:5432/license'
DB_URL = 'postgresql://postgres:ictlab2017@176.126.166.21:5432/' + DB
REDIS_URI = 'localhost'
DEBUG = True
UPLOAD_FOLDER = 'uploads/'
DOCS_FILE_UPLOAD_FOLDER = 'uploads/docs/file/'

#mail settings
MAIL_SERVER = 'smtp.googlemail.com'
MAIL_PORT =  465
MAIL_USE_TLS = False
MAIL_USE_SSL = True

#gmail authentication
MAIL_USERNAME = 'jagger773@gmail.com'
MAIL_PASSWORD = 'jugger_77'



