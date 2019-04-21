angular.module 'stock'
.constant 'stockThemeModalOptions', {
    title: 'Реестр тем'
    can_create: false
    filter: {}
    columns: []
}
.controller 'ThemeSelectController', ($scope, RequestService, $uibModalInstance, modalOptions, stockThemeModalOptions, search, $uibModal) ->
    'ngInject'
    vm = this

    vm.modalOptions = angular.merge {}, stockThemeModalOptions, angular.copy(modalOptions || {})

    vm.offset = 0
    vm.limit = 50
    vm.gridOptions =
        noUnselect: true
        paginationPageSizes: [100, 500, 1000]
        paginationPageSize: 100
        useExternalPagination: true
        appScopeProvider:
            onDoubleClick: (row) ->
                selectProduct(row.entity)
        rowTemplate: '<div ng-dblclick="grid.appScope.onDoubleClick(row)" ng-repeat="col in colContainer.renderedColumns" class="ui-grid-cell" ui-grid-cell></div>'
        columnDefs: [
            {name: 'name', displayName: 'Наименование'}
        ].reduce(
            (memo,item)->
                if vm.modalOptions.columns.length == 0 || vm.modalOptions.columns.includes item.name
                    memo.push(item)
                return memo
            ,[])
        events:
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                searchThemes(true)
                return
            onRowSelect: (row) ->
                vm.selected_theme = angular.copy row.entity
                return

    searchThemes = (paging)->
        if !paging || angular.isUndefined paging
            vm.offset = 0
        filter =
            offset: vm.offset
            limit: vm.limit
            search: vm.search_name
            with_related: true
            filter:
                theme_type: vm.modalOptions.filter.theme_type or vm.theme_type
                data:
                    category_id: vm.category_id
                    unit_id: vm.unit_id
        RequestService.post 'theme.listing', filter
        .then (result)->
            delete vm.selected_theme
            vm.gridOptions.data = result.docs
            vm.gridOptions.totalItems = result.count
            return
        return

    categoryParentGroup = (item) ->
        if !item.parent
            return ''
        return item.parent.name

    cancel = ->
        $uibModalInstance.dismiss 'cancel'
        return

    selectTheme = (selected_theme) ->
        if selected_theme
            $uibModalInstance.close selected_theme
        else if angular.isDefined vm.selected_theme
            $uibModalInstance.close vm.selected_theme
        return

    if search
        vm.search_name = if search.theme then search.theme.name
    searchThemes()

    vm.searchThemes = searchThemes
    vm.categoryParentGroup = categoryParentGroup
    vm.cancel = cancel
    vm.selectTheme = selectTheme
    return
