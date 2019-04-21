    # -*- coding: utf-8 -*-
import datetime

from app.service import chain, table_access
from flask import g, app

from sqlalchemy import desc, or_, and_, type_coerce

from app import controller
from app.service import table_access, chain
from app.model import db
from app.utils import orm_to_json
import smtplib
#! /usr/bin/python
from email.mime.text import MIMEText


@table_access(name="Dissov")
@chain(controller_name="data.listing", output=["docs"])
def listing(bag):
    pass


@table_access("Dissov")
def save(bag):
    for user in bag["composition"]:
        if user["role"] == u"Ученый секретарь":
            bag["secretary"] = user["user_id"]
        elif user["role"] == u"Зам. председателя":
            bag["vicechairman"] = user["user_id"]
        elif user["role"] == u"Председатель":
            bag["chairman"] = user["user_id"]
    statusds = g.tran.query(db.Statusds).filter_by(_deleted="infinity").all()
    for status in statusds:
        if status.name_ru == u"Активный":
            bag["statusds_id"] = status._id
    dissov = controller.call(controller_name="data.put", bag=bag)
    item = {}
    for _user in bag["composition"]:
        item["abstract"] = {}
        item["work"] = {}
        item["type"] = 'Dcomposition'
        item["dissov_id"] = dissov["id"]
        item["user_id"] = _user["user_id"]
        item["abstract"] = _user["abstract"]
        item["role"] = _user["role"]
        item["work"] = _user["work"]
        item["data"] = bag.get("data")
        controller.call(controller_name="data.put", bag=item)
    prog = {}
    for _user in bag["programs"]:
        prog["type"] = 'Dspecialty'
        prog["dissov_id"] = dissov["id"]
        prog["academicdegree_id"] = _user["academicdegree"]["academicdegree_id"]
        for bran in _user["branchesofscience"]:
            prog["branchesofscience_id"] = bran["branchesofscience_id"]
        for spec in _user["specialty"]:
            prog["specialty_id"] = spec["specialty_id"]
        prog["data"] = bag.get("data")
        controller.call(controller_name="data.put", bag=prog)
    # secretary = g.tran.query(db.User).filter(db.User.id == bag["secretary"]).one()
    # data = {
    #     'email': secretary.email,
    #     'name': secretary.first_name + '' + secretary.last_name
    # }
    # send_email(data)
    return

def remove(bag):
    o = g.tran.query(db.Dissov).filter_by(_id=bag.get('_id')).first()
    g.tran.delete(o)
    g.tran.flush()

    return {'deleted': 'ok'}


def send_email(bag):
    me = 'evak@yandex.ru'
    you = bag['email']
    html = u"""<div>
                        <p>Здравствуйте, {name}!</p>
<p>Хотим Вас, уведомить о том, что по решению на основании президиума ВАК Кыргызской Республики был создан диссертационный совет, в котором Вы явлеетесь ученым секретарем.&nbsp;</p>
                    </div> """.format(name=bag["name"])
    subj = 'Диссертационный совет в Vak.kg'

    server = "imap.yandex.ru"
    port = 993
    user_name = "info@tor.kg"
    user_passwd = "torkgadmin312"

    msg = MIMEText(html, "html", "utf-8")
    msg['Subject'] = subj
    msg['From'] = me
    msg['To'] = you

    s = smtplib.SMTP(server, port)
    s.ehlo()
    s.starttls()
    s.ehlo()
    s.login(user_name, user_passwd)
    s.sendmail(me, you, msg.as_string())
    s.quit()
    return


