# coding=utf-8
import json

from sqlalchemy import TypeDecorator, PickleType, Column, Numeric, Date, String, func, PrimaryKeyConstraint, types, ForeignKey, \
    DateTime, Integer, Enum, Float, Boolean
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.declarative import declarative_base, declared_attr
from sqlalchemy.sql.functions import now

Base = declarative_base()


class Json(TypeDecorator):
    impl = JSONB

    def load_dialect_impl(self, dialect):
        if dialect.name == 'postgresql':
            return dialect.type_descriptor(JSONB())
        else:
            return dialect.type_descriptor(PickleType(pickler=json))

    def coerce_compared_value(self, op, value):
        return self.impl.coerce_compared_value(op, value)


class ABSTIME(types.UserDefinedType):
    def get_col_spec(self):
        return 'ABSTIME'

    def bind_processor(self, dialect):
        def process(value):
            return value

        return process

    def result_processor(self, dialect, coltype):
        def process(value):
            return value

        return process


class TableId(Base):
    __tablename__ = 'table_ids'
    seq = Column(Integer, primary_key=True)
    _id = Column(String, unique=True)
    table_name = Column(String, nullable=False)
    created = Column(DateTime, default=func.now())


class Normal(object):
    @declared_attr
    def __tablename__(cls):
        return cls.__name__.lower() + 's'

    id = Column(Integer, primary_key=True)


class User(Base, Normal):
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
    middle_name = Column(String)
    email = Column(String)
    password = Column(String, nullable=False)
    confirmed = Column(Boolean, default=False)
    secure = Column(String, nullable=False)
    role = Column(Integer, nullable=False, default=0)
    rec_date = Column(DateTime, nullable=False, default=func.now())
    birthday = Column(DateTime, nullable=False)
    roles_id = Column(Json)
    citizenship_id = Column(String)
    nationality_id = Column(String)
    birthplace = Column(String)
    status = Column(String)
    data = Column(Json)


class Token(Base, Normal):
    user_id = Column(Integer, ForeignKey(User.id, ondelete='no action', onupdate='cascade'), nullable=False)
    os = Column(String)
    imei = Column(String, nullable=False)
    token = Column(String, nullable=False)
    dat_rec = Column(DateTime, nullable=False, default=now())


class CouchSync(object):
    @declared_attr
    def __tablename__(cls):
        return cls.__name__.lower()

    @declared_attr
    def _id(cls):
        return Column(String, ForeignKey(TableId._id, onupdate='cascade', ondelete='cascade'), nullable=False)

    _created = Column(ABSTIME, nullable=False, default=func.now())
    _deleted = Column(ABSTIME, nullable=False, default='infinity')
    _rev = Column(String, nullable=False, default=0)

    @declared_attr
    def entry_user_id(cls):
        return Column(Integer, ForeignKey(User.id, ondelete='no action', onupdate='cascade'))

    @declared_attr
    def __table_args__(cls):
        return PrimaryKeyConstraint('_id', '_created', '_deleted'),


class Replicator(Base, CouchSync):
    history = Column(Json)
    last_seq = Column(Integer)
    replicator = Column(String)
    session_id = Column(String)
    version = Column(String)


class Design(Base, CouchSync):
    language = Column(String)
    views = Column(Json)


class UDF(Base, CouchSync):
    name = Column(String, nullable=False)
    udf_purpose = Column(Enum('operation', 'contractor', 'user', 'branch', 'approval', 'booking', name='udf_purposes'),
                         nullable=False)
    data = Column(Json, nullable=False)


class Roles(Base, CouchSync):
    name = Column(String, nullable=False)
    menus_id = Column(Json)
    data = Column(Json)


class DirReportCategories(Base, CouchSync):
    name = Column(String, nullable=False)
    parent_id = Column(String)


class DirReportTemplates(Base, CouchSync):
    code = Column(String, nullable=False)
    name = Column(String, nullable=False)
    template = Column(Json, nullable=False)
    report_category_id = Column(String, nullable=False)


class DirReportQueries(Base, CouchSync):
    code = Column(String, nullable=False)
    name = Column(String, nullable=False)
    query = Column(String, nullable=False)


# Образование пользователя
class Education(Base, CouchSync):
    user_id = Column(Integer, nullable=False)
    organization_id = Column(String, nullable=False)
    country_id = Column(String, nullable=False)
    typeofgraduate_id = Column(String, nullable=False)
    typeoftraining_id = Column(String, nullable=False)
    date_start = Column(DateTime, nullable=False)
    date_end = Column(DateTime)
    faculty = Column(String, nullable=False)
    data = Column(Json)


# Место работы пользователя
class Work(Base, CouchSync):
    user_id = Column(Integer, ForeignKey(User.id, ondelete='no action', onupdate='cascade'), nullable=False)
    date_start = Column(ABSTIME, nullable=False)
    date_end = Column(ABSTIME)
    org_name = Column(String, nullable=False)
    pos_name = Column(String, nullable=False)
    country_id = Column(String, nullable=False)
    city = Column(String)
    data = Column(Json)


class Scientificwork(Base, CouchSync):
    user_id = Column(Integer, ForeignKey(User.id, ondelete='no action', onupdate='cascade'), nullable=False)
    name = Column(String, nullable=False)
    web_url = Column(String, nullable=False)
    journal_data = Column(Json)
    count_page = Column(Integer, nullable=False)
    coauthor = Column(Json)
    data = Column(Json)


# Работы пользователя
class Documents(Base, CouchSync):
    theme_id = Column(String, nullable=False)
    keys_word = Column(String)
    subject = Column(String)
    object = Column(String)
    goal = Column(String, nullable=False)
    methods = Column(String, nullable=False)
    results = Column(String, nullable=False)
    degreeofuse = Column(String, nullable=False)
    applicationarea = Column(String, nullable=False)
    files = Column(String)
    created_date = Column(ABSTIME, nullable=False)
    user_id = Column(Integer, nullable=False)
    data = Column(Json, default={})


# Степень пользователя
class Userdegree(Base, CouchSync):
    user_id = Column(Integer, nullable=False)
    academicdegree_id = Column(String, nullable=False)
    document_code = Column(String, nullable=False)
    documenttype_id = Column(String, nullable=False)
    actiontype_id = Column(String, nullable=False)
    action_date = Column(DateTime, nullable=False)
    attestation_department_id = Column(String, nullable=False)
    document_location = Column(String, nullable=False)
    diploma_number = Column(String)
    note = Column(String)
    data = Column(Json)


class Degreespeciality(Base, CouchSync):
    userdegree_id = Column(String, nullable=False)
    document_code = Column(String, nullable=False)
    specialty_id = Column(String)
    data = Column(Json)


# Звание пользователя
class Userrank(Base, CouchSync):
    user_id = Column(Integer, nullable=False)
    scientistrank_id = Column(String, nullable=False)
    specialtyrank_id = Column(String, nullable=False)
    organization_id = Column(String)
    date = Column(DateTime, nullable=False)
    data = Column(Json)


# Профиль пользователя
class Userprofile(Base, CouchSync):
    user_id = Column(Integer, nullable=False)
    academicdegree_id = Column(String, nullable=False)
    branchesofscience_id = Column(String, nullable=False)
    code = Column(String)
    academicdegree_date = Column(DateTime, nullable=False)
    academicrank_id = Column(String, nullable=False)
    specialty_id = Column(String, nullable=False)
    academiccouncil_id = Column(String)
    organization_id = Column(String, nullable=False)
    academicrank_date = Column(DateTime, nullable=False)
    data = Column(Json)


# Реестр тем
class Theme(Base, CouchSync):
    name = Column(String, nullable=False)
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
    middle_name = Column(String, nullable=False)
    program_id = Column(String, nullable=False)
    academicdegree_id = Column(String, nullable=False)
    branchesofscience_id = Column(String, nullable=False)
    specialty_id = Column(String, nullable=False)
    organization_id = Column(String, nullable=False)
    approval_date = Column(ABSTIME, nullable=False)
    consultant = Column(Json)
    data = Column(Json)


# Диссертационный совет
class Dissov(Base, CouchSync):
    statusds_id = Column(String, nullable=False)
    code = Column(String, nullable=False)
    number_order = Column(String, nullable=False)
    file_order = Column(String, nullable=False)
    date_start = Column(ABSTIME, nullable=False)
    date_end = Column(ABSTIME, nullable=False)
    organizations = Column(Json)
    chairman = Column(Integer)
    vicechairman = Column(Integer)
    secretary = Column(Integer)
    data = Column(Json)


# ДС специальности
class Dspecialty(Base, CouchSync):
    dissov_id = Column(String, nullable=False)
    academicdegree_id = Column(String, nullable=False)
    branchesofscience_id = Column(String, nullable=False)
    specialty_id = Column(String, nullable=False)
    data = Column(Json)


class Dcomposition(Base, CouchSync):
    dissov_id = Column(String, nullable=False)
    user_id = Column(Integer, nullable=False)
    role = Column(String)
    abstract = Column(Json)
    work = Column(Json)
    data = Column(Json)


# заявка в ДиссСовет
class DisApplication(Base, CouchSync):
    date_app = Column(ABSTIME, default=func.now())
    date_reg = Column(ABSTIME)
    user_id = Column(Integer, nullable=False)
    status = Column(String, nullable=False)
    dissov_id = Column(String, nullable=False)
    document_id = Column(String, nullable=False)
    excomposition = Column(Json)
    preview = Column(Json, default=[])
    comopinion = Column(Json, default=[])
    prejudice = Column(Json, default=[])
    protection = Column(Json, default=[])
    sequencing = Column(Json)
    oppenets = Column(Json)
    organization_id = Column(String)
    data = Column(Json)


# Замечания диссовета
class DisRemarks(Base, CouchSync):
    dissov_id = Column(String, nullable=False)
    document_id = Column(String, nullable=False)
    user_id = Column(Integer, nullable=False)
    status = Column(String, nullable=False)
    disapp_status = Column(String, nullable=False)
    remark = Column(Json, nullable=False)
    data = Column(Json)


# Электронная очередь
class Queue(Base, CouchSync):
    status = Column(String, nullable=False)
    dissov_id = Column(String, nullable=False)
    application_id = Column(String, nullable=False)
    user_id = Column(Integer, nullable=False)
    date_receipt = Column(ABSTIME, nullable=False)
    comment_receipt = Column(Json)
    date_preliminary = Column(ABSTIME, nullable=False)
    comment_preliminary = Column(Json)
    date_consul_exp = Column(ABSTIME, nullable=False)
    comment_consul_exp = Column(Json)
    date_prejudice = Column(ABSTIME, nullable=False)
    comment_prejudice = Column(Json)
    date_el_order = Column(ABSTIME, nullable=False)
    comment_el_order = Column(Json)
    date_protection = Column(ABSTIME, nullable=False)
    comment_protection = Column(Json)
    data = Column(Json)


######## Справочники ВАК  #########


class Enums(Base, CouchSync):
    name = Column(String, nullable=False)
    data = Column(Json)


# Меню
class Menus(Base, CouchSync):
    name = Column(String, nullable=False)
    parent_id = Column(String)
    data = Column(Json)


# Страны
class Countries(Base, CouchSync):
    name_ru = Column(String, nullable=False)
    name_kg = Column(String)
    data = Column(Json, default={})


# Категория организации
class Categoryorganization(Base, CouchSync):
    name_ru = Column(String, nullable=False)
    name_kg = Column(String)
    data = Column(Json, default={})


# отделы категории организации
class Departmentcategory(Base, CouchSync):
    name_ru = Column(String, nullable=False)
    name_kg = Column(String)
    categoryorganization_id = Column(String)
    data = Column(Json, default={})


# Организации
class Organizations(Base, CouchSync):
    name_ru = Column(String, nullable=False)
    name_kg = Column(String)
    categoryorganization_id = Column(String)
    departmentcategory_id = Column(String)
    data = Column(Json, default={})


# Академическое звание
class Academicrank(Base, CouchSync):
    name_ru = Column(String, nullable=False)
    name_kg = Column(String)
    data = Column(Json, default={})


# Ученое звание
class Scientistrank(Base, CouchSync):
    name_ru = Column(String, nullable=False)
    name_kg = Column(String)
    data = Column(Json, default={})


# Национальность
class Nationality(Base, CouchSync):
    name_ru = Column(String, nullable=False)
    name_kg = Column(String)
    data = Column(Json, default={})


# Гражданство
class Citizenship(Base, CouchSync):
    name_ru = Column(String, nullable=False)
    name_kg = Column(String)
    data = Column(Json, default={})


# Ученая степень
class Academicdegree(Base, CouchSync):
    code = Column(String, nullable=False)
    name_ru = Column(String, nullable=False)
    name_kg = Column(String)
    data = Column(Json, default={})


# Статус ДС
class Statusds(Base, CouchSync):
    name_ru = Column(String, nullable=False)
    name_kg = Column(String)
    data = Column(Json, default={})


# Отрасли науки
class Branchesofscience(Base, CouchSync):
    code = Column(String)
    name_ru = Column(String, nullable=False)
    name_kg = Column(String)
    data = Column(Json, default={})


# Под отрасль науки
class Subbranchesofscience(Base, CouchSync):
    code = Column(String)
    name_ru = Column(String, nullable=False)
    name_kg = Column(String)
    data = Column(Json, default={})


# Специальность по специальности
class Specialty(Base, CouchSync):
    code = Column(String, nullable=False)
    name_ru = Column(String, nullable=False)
    name_kg = Column(String)
    data = Column(Json, default={})


# Специальность по званию
class Specialtyrank(Base, CouchSync):
    name_ru = Column(String, nullable=False)
    name_kg = Column(String)
    data = Column(Json, default={})


# Должности
class Positions(Base, CouchSync):
    name_ru = Column(String, nullable=True)
    name_kg = Column(String)
    data = Column(Json, default={})


# Пол
class Male(Base, CouchSync):
    name_ru = Column(String, nullable=True)
    name_kg = Column(String)
    data = Column(Json, default={})


# Программы
class Program(Base, CouchSync):
    name_ru = Column(String, nullable=True)
    name_kg = Column(String)
    data = Column(Json, default={})


# Форма обучения
class Typeofgraduate(Base, CouchSync):
    name_ru = Column(String, nullable=True)
    name_kg = Column(String)
    data = Column(Json, default={})


# Вид обучения
class Typeoftraining(Base, CouchSync):
    name_ru = Column(String, nullable=True)
    name_kg = Column(String)
    data = Column(Json, default={})


# Вид документа
class Documenttype(Base, CouchSync):
    name_ru = Column(String, nullable=True)
    name_kg = Column(String)
    data = Column(Json, default={})


# Отделы аттестации
class Attestation_department(Base, CouchSync):
    name_ru = Column(String, nullable=True)
    name_kg = Column(String)
    data = Column(Json, default={})


class Actiontype(Base, CouchSync):
    name_ru = Column(String, nullable=True)
    name_kg = Column(String)
    data = Column(Json, default={})


# Разделы нормативных документов
class Departmentdocument(Base, CouchSync):
    name_ru = Column(String, nullable=True)
    name_kg = Column(String)
    data = Column(Json, default={})


# Журналы
class Journals(Base, CouchSync):
    name_ru = Column(String, nullable=False)
    name_kg = Column(String, nullable=False)
    about = Column(String, nullable=False)
    issn_print_v = Column(String, nullable=False)
    issn_electronic_v = Column(String, nullable=False)
    signature_index = Column(String, nullable=False)
    founder = Column(String, nullable=False)
    address = Column(String, nullable=False)
    phones = Column(Json, nullable=False)
    fax = Column(Json, nullable=False)
    email = Column(String, nullable=False)
    info_card_rins = Column(String)
    info_card_wos = Column(String)
    info_card_scopus = Column(String)
    requirements = Column(String)
    img_url = Column(String)


# Статьи
class Articles(Base, CouchSync):
    udk = Column(String, nullable=False)
    topics = Column(Json, nullable=False)
    authors = Column(Json, nullable=False)
    name_ru = Column(String, nullable=False)
    name_kg = Column(String, nullable=False)
    annotation_ru = Column(String, nullable=False)
    annotation_kg = Column(String, nullable=False)
    keywords_ru = Column(String, nullable=False)
    keywords_kg = Column(String, nullable=False)
    language = Column(String, nullable=False)
    year = Column(Integer, nullable=False)
    volume = Column(Integer, nullable=False)
    number = Column(Integer, nullable=False)
    page_start = Column(Integer, nullable=False)
    page_end = Column(Integer, nullable=False)
    file = Column(String, nullable=False)
    review = Column(String)
    doi = Column(String)
    note = Column(String)
    journal_id = Column(String)


class Topics(Base, CouchSync):
    name_ru = Column(String, nullable=False)
    name_kg = Column(String, nullable=False)


#Новости
class New(Base, CouchSync):
    sectionsofpublication_id = Column(String, nullable=False)
    name_ru = Column(String, nullable=False)
    name_kg = Column(String)
    description = Column(Json)
    description_kg = Column(String)
    link = Column(String)
    created_from = Column(ABSTIME, nullable=False, default=func.now())
    is_active = Column(Boolean, default=False)
    files = Column(Json)


#Нормативные Документы
class Regulation(Base, Normal):
    name_ru = Column(String, nullable=False)
    name_kg = Column(String, nullable=False)
    created_from = Column(ABSTIME, nullable=False, default=func.now())
    created_to = Column(ABSTIME, nullable=False, default='infinity')
    file = Column(String)
    departmentdocument_id = Column(String, nullable=False)
    order = Column(Integer)
    data = Column(Json)


#Объявления
class Advert(Base, Normal):
    name_ru = Column(String, nullable=False)
    name_kg = Column(String, nullable=False)
    description_ru = Column(String, nullable=False)
    description_kg = Column(String, nullable=False)
    link = Column(String, nullable=False)
    created_from = Column(ABSTIME, nullable=False, default=func.now())
    created_to = Column(ABSTIME, nullable=False, default='infinity')
    is_active = Column(Boolean, default=False)
    file = Column(String)


#Вопросы и ответы
class Question(Base, Normal):
    name = Column(String, nullable=False)
    city = Column(String, nullable=False)
    email = Column(String, nullable=False)
    url = Column(String, nullable=False)
    question = Column(String, nullable=False)
    created_from = Column(ABSTIME, nullable=False, default=func.now())
    created_to = Column(ABSTIME, nullable=False, default='infinity')
    is_active = Column(Boolean, default=False)
    answer = Column(String)


class log(Base, Normal):
    user_id = Column(Integer, nullable=False)
    created_date = Column(ABSTIME, nullable=False)
    operation = Column(Json, default={})
    data = Column(Json)


# Разделы публикации
class Sectionsofpublication(Base, CouchSync):
    name_ru = Column(String, nullable=False)
    name_kg = Column(String)
    order = Column(Integer)
    data = Column(Json)


#Баннеры
class Banners(Base, CouchSync):
    file = Column(String, nullable=False)
    link = Column(String)
