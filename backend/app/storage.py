import base64
import hashlib
import pickle
import uuid
from collections import defaultdict
from time import sleep

from flask import g
from sqlalchemy import func
from sqlalchemy.orm.exc import NoResultFound

from app.model import db
from app.model.db import CouchSync
from app.utils import json_to_orm, orm_to_json


class PostgresDatabase:
    def __init__(self):
        pass

    class Conflict(Exception):
        """Raises in case of conflict updates"""

    class NotFound(Exception):
        """Raises in case attempt to query on missed document"""

    class TypeMissing(Exception):
        """Raises when type is missing"""

    def __get_object(self, name):
        m = __import__('app.model.db')
        m = getattr(m, 'model')
        m = getattr(m, 'db')
        m = getattr(m, name)
        return m

    def _new_rev(self, doc):
        oldrev = doc.get('_rev')
        if oldrev is None:
            seq, _ = 0, None
        else:
            seq, _ = oldrev.split('-', 1)
            seq = int(seq)
        sig = hashlib.md5(pickle.dumps(doc)).hexdigest()
        newrev = '%d-%s' % (seq + 1, sig)
        return newrev.lower()

    def check_for_conflicts(self, idx, rev):
        if self.contains(idx):
            if rev is None:
                if idx.startswith('_local/'):
                    return
                raise self.Conflict('Document update conflict')
            elif not self.contains(idx, rev):
                raise self.Conflict('Document update conflict')
        elif rev is not None:
            raise self.Conflict('Document update conflict')

    def contains(self, idx, rev=None):
        doc = g.tran.query(db.TableId).filter_by(_id=idx).first()
        if doc is None:
            return False
        table = self.__get_object(doc.table_name)
        doc = g.tran.query(table).filter_by(_id=idx).order_by(table._created)
        if rev is None:
            return True
        doc = doc.filter_by(_rev=rev).first()
        if doc is None:
            return False
        return True

    def load(self, idx, rev=None, revs=False, as_dict=True, locked=False):
        if not self.contains(idx, rev):
            raise self.NotFound(idx)
        ti = g.tran.query(db.TableId).filter_by(_id=idx)
        if locked:
            ti = ti.with_for_update(of=db.TableId)
        ti = ti.first()
        table = self.__get_object(ti.table_name)
        doc = g.tran.query(table).filter_by(_id=idx)
        if rev:
            doc = doc.filter_by(_rev=rev)
        else:
            doc = doc.filter_by(_deleted='infinity')
        doc = doc.first()
        if not doc:
            raise self.NotFound(idx)
        setattr(doc, 'type', ti.table_name)
        d = orm_to_json(doc)
        d['type'] = ti.table_name
        del d['_created']
        del d['_deleted']
        if doc._deleted != 'infinity':
            d['_deleted'] = True
        if revs:
            d['_revisions'] = {'ids': []}
            sql = g.tran.query(table).filter_by(_id=idx).order_by(table._created.desc())
            for r in sql:
                d['_revisions']['ids'] = r._rev.split('-')[1]
                if not d['_revisions'].get('start'):
                    d['_revisions']['start'] = r._rev.split('-')[0]
        if as_dict:
            return d
        return doc

    def store(self, doc, rev=None, new_edits=True):
        table = None
        if '_local' in doc.get('_id', {}):
            doc['type'] = 'Replicator'
        if '_design' in doc.get('_id', {}):
            doc['type'] = 'Design'
        if 'type' not in doc:
            raise self.TypeMissing()
        if '_id' not in doc:
            doc['_id'] = self._generate_id(doc['type'])
        if rev is None:
            rev = doc.get('_rev')

        if new_edits:
            doc['_rev'] = self._new_rev(doc)
        else:
            assert rev, 'Document revision missed'
            doc['_rev'] = rev
        try:
            if not table:
                table = self.__get_object(doc['type'])
                if issubclass(table, CouchSync):
                    doc['entry_user_id'] = g.user.id
        except:
            raise self.TypeMissing()
        try:
            t = g.tran.query(table).filter_by(_id=doc['_id'], _deleted='infinity').with_for_update(of=table).one()
        except NoResultFound:
            t = table()
            self._generate_id(doc['type'], doc['_id'])
        json_to_orm(doc, t)
        g.tran.add(t)
        g.tran.flush()
        return t._id, t._rev

    def remove(self, idx, rev):
        if not self.contains(idx):
            return idx, rev
        try:
            doc = self.load(idx, as_dict=False, locked=True)
        except self.NotFound:
            return idx, rev
        doc._rev = rev
        doc._rev = self._new_rev(orm_to_json(doc))
        g.tran.flush()
        try:
            doc = self.load(idx, as_dict=False, locked=True)
        except self.NotFound:
            return idx, rev
        g.tran.delete(doc)
        g.tran.flush()
        return doc._id, doc._rev

    def revs_diff(self, idrevs):
        res = defaultdict(dict)
        for idx, revs in idrevs.items():
            missing = []
            if not self.contains(idx):
                missing.extend(revs)
                res[idx]['missing'] = missing
                continue
            t = g.tran.query(db.TableId).filter(db.TableId._id == idx).one()
            table = self.__get_object(t.table_name)
            doc = g.tran.query(table).filter_by(_id=idx, _deleted='infinity').first()
            for rev in revs:
                if not doc or doc._rev != rev:
                    missing.append(rev)
            if missing:
                res[idx]['missing'] = missing
        return res

    def bulk_docs(self, docs, new_edits=True):
        res = []
        for doc in docs:
            try:
                if doc.get('_deleted'):
                    idx, rev = self.remove(doc['_id'], doc['_rev'])
                else:
                    idx, rev = self.store(doc, None, new_edits)
                res.append({
                    'ok': True,
                    'id': idx,
                    'rev': rev
                })
            except Exception as err:
                res.append({'id': doc.get('_id'),
                            'error': type(err).__name__,
                            'reason': str(err)})
        return res

    def ensure_full_commit(self):
        return {
            'ok': True
        }

    def changes(self, since=0, feed='normal', style='all_docs', filter=None, limit=None, timeout=25):
        if feed == 'longpoll':
            sleep(timeout / 2)
        sql = self.__get_id_sql().offset(since)
        if limit:
            sql = sql.limit(limit)
        docs = []
        s = 0
        for r in sql:
            docs.append(self.make_event(r, style))
            s = r.seq
        return docs, s

    def add_attachment(self, doc, name, data, ctype='application/octet-stream'):
        atts = doc.setdefault('_attachments')
        digest = 'md5-%s' % base64.b64encode(hashlib.md5(data).digest()).decode()
        if doc.get('_rev'):
            revpos = int(doc['_rev'].split('-')[0]) + 1
        else:
            revpos = 1
        atts[name] = {
            'data': data,
            'digest': digest,
            'length': len(data),
            'content_type': ctype,
            'revpos': revpos
        }

    def make_event(self, r, style):
        table = self.__get_object(r.table_name)
        doc = g.tran.query(table).filter_by(_id=r._id).order_by(table._created.desc())
        event = {
            'id': r._id,
            'changes': [],
            'seq': r.seq
        }
        i = 0
        for d in doc:
            event['changes'].append({'rev': d._rev})
            if i == 0 and d._deleted != 'infinity':
                event['_deleted'] = True
            if style == 'main_only':
                break
            i += 1
        return event

    def _generate_id(self, table, _id=None):
        if not _id:
            _id = str(uuid.uuid4()).lower()
        try:
            ti = g.tran.query(db.TableId).filter(db.TableId._id == _id).with_for_update(of=db.TableId).one()
        except NoResultFound:
            ti = db.TableId()
            ti._id = _id
        ti.table_name = table
        g.tran.add(ti)
        g.tran.flush()
        return ti._id

    def all_docs(self, **kwargs):
        sql = self.__get_id_sql()
        if kwargs.get('keys'):
            sql = sql.filter(db.TableId._id.in_(kwargs['keys']))
        rows = []
        for d in sql:
            r = {'id': d._id, 'value': {}}
            table = self.__get_object(d.table_name)
            doc = g.tran.query(table).filter_by(_id=d._id, _deleted='infinity').one()
            r['value']['rev'] = doc._rev
            if kwargs.get('include_docs', False):
                r['doc'] = orm_to_json(doc)
                r['doc']['type'] = d.table_name
                del r['doc']['_created']
                del r['doc']['_deleted']
            rows.append(r)
        return {'offset': 0, 'rows': rows}

    def __get_id_sql(self):
        return g.tran.query(db.TableId) \
            .filter(~db.TableId.table_name.in_([db.Replicator.__name__])) \
            .order_by(db.TableId.created)

    def info(self):
        maxId = g.tran.query(func.max(db.TableId.seq)).scalar()
        return {'name': g.tran.bind.name, 'instance_start_time': 0,
                'update_seq': maxId,
                'commited_update_seq': maxId}
