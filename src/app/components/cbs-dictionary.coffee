'use strict'
angular.module('stock')
.directive 'cbsDict', (BObjectService) ->
    link: (scope, element) ->
        table = element.attr('cbs-dict')
        BObjectService.list(table).then (data) ->
            scope[table] = angular.copy(data.docs)
            return
        return

