# coding=utf-8
from mailjet_rest import Client
import os

API_KEY = '95fb3c407e24b57cd93b68778c238ca9'
API_SECRET = 'a0886868fc6c970e535a7be5738a6449'
FROM_EMAIL = 'evak@yandex.ru'
FROM_NAME = ''
mailjet = Client(auth=(API_KEY, API_SECRET))


def send(data):

    htmlpart = u"""<div>
                        <table style="font-family: arial, sans-serif; max-width: 700px;min-width: 500px;">
                        <thead>
                          <tr>
                            <th colspan="2" style="text-align: center; padding: 8px;">Данные полиса</th>
                          </tr>
                          <tr>
                            <th style="text-align: left;padding: 8px; font-weight:bold;">Номер полиса</th>
                            <th style="text-align: left;padding: 8px; font-style:italic;"><h2> <span style="color: red;">{policy_no}</span></h2></th>
                          </tr>
                          <tr>
                            <th style="text-align: left;padding: 8px; font-weight:bold;">Период страхования</th>
                            <th style="text-align: left;padding: 8px; font-style:italic;"><span style="color: green;">{date_start}</span> - <span style="color: green;">{date_end}</span></th>
                          </tr>
                        </thead>
                        <tbody>
                          <tr>
                            <td style="text-align: left;padding: 8px; font-weight:bold;">Страховая сумма</td>
                            <td style="text-align: left;padding: 8px; font-style:italic;">{insurance_amount} {currency_name}</td>
                          </tr>
                          <tr>
                            <td style="text-align: left;padding: 8px; font-weight:bold;">Страны</td>
                            <td style="text-align: left;padding: 8px; font-style:italic;">{countries}</td>
                          </tr>
                          <tr>
                            <td style="text-align: left;padding: 8px; font-weight:bold;">Страховая премия</td>
                            <td style="text-align: left;padding: 8px; font-style:italic;">{insurance_premium} {currency_name}</td>
                          </tr>
                          <tr>
                            <td style="text-align: left;padding: 8px; font-weight:bold;">Фио клиента</td>
                            <td style="text-align: left;padding: 8px; font-style:italic;">{surname} {name}</td>
                          </tr>
                          <tr>
                            <td style="text-align: left;padding: 8px; font-weight:bold;">Дата рождения</td>
                            <td style="text-align: left;padding: 8px; font-style:italic;">{date_of_birth}</td>
                          </tr>
                          <tr>
                            <td style="text-align: left;padding: 8px; font-weight:bold;">Номер паспорта</td>
                            <td style="text-align: left;padding: 8px; font-style:italic;">{passport_no}</td>
                          </tr>
                          <tr>
                            <td style="text-align: left;padding: 8px; font-weight:bold;">Статус</td>
                            <td style="text-align: left;padding: 8px; font-style:italic;">{status}</td>
                          </tr>
                        </tbody>
                      </table>
                      <h3>Спасибо за покупку. Приходите еще. :)</h3>
                    </div> """.format(policy_no=data["policy_no"], date_start=data["date_start"], date_end=data["date_end"],
                                      insurance_amount=data["insurance_amount"], insurance_premium=data["insurance_premium"],
                                      surname=data["surname"], name=data["name"], date_of_birth=data["date_of_birth"],
                                      passport_no=data["passport_no"], status=data["status"], countries=data["countries"],
                                      currency_name=data["currency_name"])

    """
    mailjet docs link:  https://dev.mailjet.com/guides/

    Example:

    data = {
        'FromEmail': 'kairat@erp.kg',
        'FromName': 'Mailjet Pilot',
        'Subject': 'Your email flight plan!',
        'Text-part': 'Dear passenger, welcome to Mailjet! May the delivery force be with you!',
        'Html-part': '<h3>Dear passenger, welcome to Mailjet!</h3><br />May the delivery force be with you!',
        'Recipients': [{'Email':'kairat.mail2012@gmail.com'}]
    }
    result = mailjet.send.create(data=data)
    print result.status_code
    print result.json()
    """
    data = {
        'FromEmail': 'kairat@erp.kg',
        'FromName': 'Kamkor IPS',
        'Subject': 'Policy is issued!',
        'Text-part': '',
        'Html-part': htmlpart,
        'Recipients': [{'Email': data["email"]}]
    }
    if not isinstance(data, dict):
        raise Exception("argument data must be dict")
    result = mailjet.send.create(data=data)
    return {"status": result.status_code, "reason": result.reason}

