angular.module 'stock'
.constant 'pagedTableOptions', {
    noUnselect: true
    enableRowSelection: true
    enableRowHeaderSelection: false
    multiSelect: false
    saveWidths: true
    enableGridMenu: true
    gridMenuCustomItems: []
    events: {}
}
.directive 'pagedTable', ($location, $rootScope, pagedTableOptions) ->
    link = (scope, el, attr) ->
        if angular.isUndefined(scope.options)
            scope.options = {}
        scope.options = angular.merge {}, pagedTableOptions, scope.options

        scope.options.onRegisterApi = (gridApi) ->
            scope.options.gridApi = gridApi
            gridApi.selection.on.rowSelectionChanged scope, (row) ->
                if scope.options.events.onRowSelect and scope.options.events.onRowSelect instanceof Function
                    scope.options.events.onRowSelect row
            gridApi.cellNav.on.navigate scope, (newRowCol) ->
                gridApi.selection.selectRow(newRowCol.row.entity)
            if gridApi.pagination
                gridApi.pagination.on.paginationChanged scope, (newPage, pageSize) ->
                    if scope.options.events.onPageSelect and scope.options.events.onPageSelect instanceof Function
                        scope.options.events.onPageSelect newPage - 1, pageSize
            return

        scope.$watch 'query', ()->
            if scope.options.events.onSearch and scope.options.events.onSearch instanceof Function
                scope.options.events.onSearch scope.query

        scope.attr = {}
        if attr.disablePaging and attr.disablePaging != 'false'
            delete scope.attr.pagination
        else
            scope.attr.pagination = true
        if attr.enableEdit and attr.enableEdit != 'false'
            scope.attr.edit = true
        else
            delete scope.attr.edit

        return
    {
        restrict: 'E'
        link: link
        transclude: true
        scope: {
            options: '='
            disablePaging: '@'
            disableSearch: '@'
            enableEdit: '@'
            height: '@'
        }
        template: (element, attr) ->
            pagination = if attr.disablePaging and attr.disablePaging != 'false' then '' else 'ui-grid-pagination'
            edit = if attr.enableEdit and attr.enableEdit != 'false' then 'ui-grid-edit' else ''
            return [
                "<div>",
                "  <div class='form-group'>",
                "    <input ng-hide='disableSearch' type='search' ng-model='query' ng-model-options='{debounce:200}' placeholder='Поиск' autofocus class='form-control'>",
                "  </div>",
                "  <div ui-grid='options' ui-grid-selection ui-grid-resize-columns ui-grid-cellNav #{pagination} #{edit} class='grid' ng-style='{height:height}'></div>",
                "</div>"
            ].join("")
    }
