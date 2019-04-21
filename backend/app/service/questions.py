# coding=utf-8
import datetime

from flask import g

from sqlalchemy import desc, or_, and_, type_coerce

from app.controller import entity
from app.keys import CRUD, BOBJECT
from app.model import db
from app.utils import orm_to_json
from app import keys,controller




def listing(bag):
    query = g.tran.query(db.Question)
    if bag.get('name'):
        query = query.filter(db.Question.name.ilike('%' + bag.get('name') + '%'))
    if bag.get('created_from'):
        query = query.filter(db.Question.created_from >= bag.get('created_from'))
    if bag.get('created_to'):
        query = query.filter(db.Question.created_to <= bag.get('created_to'))
    if bag.get('is_active'):
        active = bag.get('is_active')
        if active == 'yes':
            query = query.filter_by(is_active=True)
        elif active == 'no':
            query = query.filter_by(is_active=False)
    query = query.order_by(desc(db.Question.created_from))
    questions = query.all()
    items = []
    for _questions in questions:
        item = orm_to_json(_questions)
        items.append(item)

    return {'list': items}


def put_question(bag):
    question = g.tran.query(db.Question).filter_by(id=bag.get('id')).first()
    question = question if question else db.Question()
    question.name = bag.get('name')
    question.city = bag.get('city')
    question.email = bag.get('email')
    question.url = bag.get('url')
    question.question = bag.get('question')

    g.tran.add(question)

    return {'response': 'OK'}

def put_answer(bag):
    answer = g.tran.query(db.Question).filter_by(id=bag.get('id')).first()
    answer = answer if answer else db.Question()
    answer.answer = bag.get('answer')
    answer.is_active = bag.get('is_active')
    g.tran.add(answer)

    return {'answer': orm_to_json(answer)}


def remove(bag):
    o = g.tran.query(db.Question).filter_by(id=bag['id']).first()
    g.tran.delete(o)
    g.tran.flush()
    return




