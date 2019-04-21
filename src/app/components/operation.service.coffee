angular.module 'stock'
.service 'OpService', (db)->
    service = this
    service.sale = (invoice)->
        docs = [{type: 'sale', data: invoice}]
        angular.forEach invoice.products, (p)->
            docs.push({type: 'stock_record', data: {product_id: p.id, count: -p.count}})
        db.insert docs
    service.purchase = ()->
        docs = [{type: 'purchase', data: invoice}]
        angular.forEach invoice.products, (p)->
            docs.push({type: 'stock_record', data: {product_id: p.id, count: p.count}})
        db.insert docs
    return service
