# coding=utf-8
from flask import g

from app import orm_to_json
from app.model import db
from app.service import table_access, chain

tables = [
    {
        'table': 'Branchesofscience',
        'display_name': u'BRANCHOFSCIENCE_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'code', 'displayName': u'CODE_SPAN_LABEL'},
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Subbranchesofscience',
        'display_name': u'SUBBRANCHOFSCIENCE_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'code', 'displayName': u'CODE_SPAN_LABEL'},
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Specialty',
        'display_name': u'SPECIALITY_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'code', 'displayName': u'CODE_SPAN_LABEL'},
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Specialtyrank',
        'display_name': u'SPECIALITYRANK_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Positions',
        'display_name': u'POSITIONS_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Countries',
        'display_name': u'COUNTRIES_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Categoryorganization',
        'display_name': u'CATEGORY_ORGANIZATION_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Departmentcategory',
        'display_name': u'DEPARTMENT_CATEGORY_ORGANIZATION_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'categoryorganization.name_ru', 'displayName': u'CATEGORY_ORGANIZATION_DIR_LABEL'},
        ]
    },
    {
        'table': 'Organizations',
        'display_name': u'ORGANIZATION_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'categoryorganization.name_ru', 'displayName': u'CATEGORY_ORGANIZATION_DIR_LABEL'},
            {'name': 'departmentcategory.name_ru', 'displayName': u'DEPARTMENT_CATEGORY_ORGANIZATION_DIR_LABEL'},
        ]
    },
    {
        'table': 'Academicrank',
        'display_name': u'ACADEMICRANK_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Scientistrank',
        'display_name': u'SCIENTISTRANK_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Academicdegree',
        'display_name': u'ACADEMICDEGREE_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Nationality',
        'display_name': u'NATIONALITY_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Citizenship',
        'display_name': u'CITIZENSHIP_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Statusds',
        'display_name': u'STATUSDS_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Male',
        'display_name': u'MALE_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Typeofgraduate',
        'display_name': u'TYPEOFGRADUATE_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Typeoftraining',
        'display_name': u'TYPEOFTRAINIG_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Topics',
        'display_name': u'TOPIC_DIR_LABEL',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Program',
        'display_name': u'Программы',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Documenttype',
        'display_name': u'Вид документа',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Attestation_department',
        'display_name': u'Отделы аттестации',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Actiontype',
        'display_name': u'Тип действия',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Departmentdocument',
        'display_name': u'Разделы норм. документов',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'NAME_RU_SPAN_LABEL'},
            {'name': 'name_kg', 'displayName': u'NAME_KG_SPAN_LABEL'},
        ]
    },
    {
        'table': 'Enums',
        'display_name': u'Типы/Статусы',
        'role_requires': 10,
        'columns': [
            {'name': 'name', 'displayName': u'Тип'},
            {'name': 'data.name', 'displayName': u'Наименование'},
            {'name': 'data.key', 'displayName': u'Ключ'}
        ]
    },
    {
        'table': 'Sectionsofpublication',
        'display_name': u'Разделы Новостей/публикации',
        'role_requires': 10,
        'columns': [
            {'name': 'name_ru', 'displayName': u'Наименование'},
            {'name': 'order', 'displayName': u'Порядок'}
        ]
    },
    {
        'table': 'Roles',
        'list_only': True
    },
    {
        'table': 'PricingRules',
        'list_only': True
    },
    {
        'table': 'Branches',
        'list_only': True
    },
    {
        'table': 'ReportQueries',
        'list_only': True
    },
    {
        'table': 'Sector',
        'list_only': True
    }
]


def tables_list(bag):
    ret = []
    for table in tables:
        if ('role_requires' not in table or g.user.role >= table['role_requires']) and \
                ('list_only' not in table or table['list_only'] is False):
            ret.append(table)
    return {'tables': ret}


def table_names(option):
    ret = []
    for table in tables:
        if option is not 'put' or 'list_only' not in table or table['list_only'] is False or \
                'role_requires' not in table or g.user.role >= table['role_requires']:
            ret.append(table['table'])
    return ret


@table_access(names=table_names('get'))
@chain(controller_name='data.get', output=['doc'])
def get(bag):
    pass


@table_access(names=table_names('list'))
@chain(controller_name='dictionary.listing')
def listing(bag):
    return {"docs": bag["docs"], "count": bag["count"], "table": bag["type"]}


@table_access(names=table_names('put'))
@chain(controller_name='data.put', output=['id', 'rev'])
def save(bag):
    pass


@table_access(names=table_names('put'))
@chain(controller_name='data.delete', output=['id', 'rev'])
def remove(bag):
    pass

