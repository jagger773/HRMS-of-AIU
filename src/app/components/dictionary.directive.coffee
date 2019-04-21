angular.module 'stock'
.directive 'stockDict', (BObjectService)->
    restrict: 'A'
    scope:
        stockDict: '='
        dictTable: '@'
        dictFilter: '='
        dictFirstItem: '='
        dictOptions: '='
        dictOnLoad: '&'
    link: (scope, element, attr)->
        lastParams = null
        getDict = ->
            params =
                stockDict: scope.stockDict
                dictTable: scope.dictTable
                dictFilter: scope.dictFilter
                dictFirstItem: scope.dictFirstItem
                dictOptions: scope.dictOptions
            if angular.equals lastParams, params
                return
            lastParams = params
            filter =
                type: scope.dictTable
                with_related: true
                filter: scope.dictFilter
            BObjectService.list filter.type, filter
            .then (data) ->
                if angular.isDefined scope.dictOptions
                    if scope.dictOptions.onlyParents == true
                        dicts = (dict for dict in data.docs when dict.parent_id == null || angular.isUndefined dict.parent_id)
                    else if scope.dictOptions.onlyChildren == true
                        dicts = (dict for dict in data.docs when dict.parent_id != null && angular.isDefined dict.parent_id)
                    if angular.isUndefined dicts
                        dicts = angular.copy(data.docs)
                else
                    dicts = angular.copy(data.docs)
                if angular.isDefined scope.dictFirstItem
                    dicts.unshift scope.dictFirstItem
                scope.stockDict = dicts
                setTimeout ->
                    if scope.dictOnLoad and scope.dictOnLoad instanceof Function
                        scope.dictOnLoad()
                , 0
                return
            return
        scope.$watch 'dictTable', (oldVal, newVal)->
            if angular.isDefined newVal
                getDict()
            return
        scope.$watch 'dictFilter', (oldVal, newVal)->
            if angular.isDefined newVal
                getDict()
            return
        scope.$watch 'dictFirstItem', (oldVal, newVal)->
            if angular.isDefined newVal
                getDict()
            return
        scope.$watch 'dictOptions', (oldVal, newVal)->
            if angular.isDefined newVal
                getDict()
            return
        return
