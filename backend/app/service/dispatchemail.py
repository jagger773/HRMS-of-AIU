# coding: utf-8

import smtplib
#! /usr/bin/python
from email.mime.text import MIMEText


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
