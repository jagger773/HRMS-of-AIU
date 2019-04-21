(function () {
    'use strict';

    angular
        .module('stock')
        .factory('db', function (pouchDB, pouchDBDecorators, $q, $rootScope, moment, RequestService) {
            var db = this.instance = pouchDB('apex');
            db.seach = pouchDBDecorators.qify(db.search);
            this.instance.getIndexes().then(function (result) {
                for (var i = 0; i < result.indexes.length; i++) {
                    var index = result.indexes[i];
                    if (index.ddoc && index.ddoc.indexOf('index_type') > -1) {
                        return;
                    }
                }
                db.createIndex({
                    index: {
                        fields: ['type'],
                        ddoc: 'index_type'
                    }
                }).then(function () {
                    db.find = pouchDBDecorators.qify(db.find);
                });
            });
            // this.serverName = 'http://192.168.0.236:5984/stock_dev';
            this.serverName = 'http://192.168.0.236:7000/sync/stock_dev';
            this.started = false;
            this.syncFromServer = function () {
                this.instance.replicate.from(this.serverName);
            };

            this.select = function (type, limit, offset) {
                var args = {selector: {type: type}};
                if (limit) {
                    args.limit = limit;
                }
                if (offset) {
                    args.skip = offset;
                }
                return db.find(args)
            };
            this.search = function (type, query, columns, limit, offset) {
                var opts = {};
                opts.filter = function (doc) {
                    return doc.type === type;
                };
                opts.query = query;
                opts.fields = columns;
                opts.include_docs = true;
                opts.language = ['en', 'ru'];
                if (limit) {
                    opts.limit = limit;
                    opts.skip = 0;
                }
                if (offset) {
                    opts.skip = offset;
                }
                var q = $q.defer();
                db.search(opts).then(function (result) {
                    var docs = [];
                    angular.forEach(result.rows, function (row) {
                        docs.push(row.doc);
                    });
                    console.log(docs);
                    q.resolve({docs: docs, total_rows: result.total_rows});
                });
                return q.promise;
            };
            this.count = function (type) {
                var myMapReduceFun = {
                    map: function (doc) {
                        emit(doc.type);
                    },
                    reduce: '_count'
                };
                return db.query(myMapReduceFun, {
                    key: type, reduce: true, group: true
                }).catch(function (e) {
                    console.log(e);
                });
            };
            this.save = function (type, data, id, rev) {
                var entity = {
                    data: data,
                    type: type,
                    company: $rootScope.company,
                    branch: $rootScope.branch,
                    user: $rootScope.user,
                    date: moment().format('DD/MM/YYYY HH:mm:ss')
                };
                if (id) {
                    entity._id = id;
                    if (rev) {
                        entity._rev = rev;
                    }
                    return db.put(entity).catch(function (e) {
                        console.log(e);
                    });
                }
                return db.post(entity).catch(function (e) {
                    console.log(e);
                });
            };
            this.insert = function (docs) {
                angular.forEach(docs, function (d) {
                    d.company = $rootScope.company;
                    d.branch = $rootScope.branch;
                    d.user = $rootScope.user;
                    d.date = moment().format('DD/MM/YYYY HH:mm:ss');
                });
                return db.bulkDocs(docs)
            };
            return this;
        });
})();
