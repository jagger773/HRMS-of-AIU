angular.module 'stock'
.constant 'stockProductModalOptions', {
    title: 'Реестр тем'
    can_create: false
    filter: {}
    columns: []
}
.controller 'ProductSelectController', ($scope, RequestService, $uibModalInstance, modalOptions, stockProductModalOptions, search, $uibModal) ->
    'ngInject'
    vm = this

    vm.modalOptions = angular.merge {}, stockProductModalOptions, angular.copy(modalOptions || {})

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
                searchProducts(true)
                return
            onRowSelect: (row) ->
                vm.selected_product = angular.copy row.entity
                return

    searchProducts = (paging)->
        if !paging || angular.isUndefined paging
            vm.offset = 0
        filter =
            offset: vm.offset
            limit: vm.limit
            search: vm.search_name
            with_related: true
            filter:
                product_type: vm.modalOptions.filter.product_type or vm.product_type
                data:
                    category_id: vm.category_id
                    unit_id: vm.unit_id
        RequestService.post 'theme.listing', filter
        .then (result)->
            delete vm.selected_product
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

    selectProduct = (selected_product) ->
        if selected_product
            $uibModalInstance.close selected_product
        else if angular.isDefined vm.selected_product
            $uibModalInstance.close vm.selected_product
        return

    if search
        vm.search_name = if search.product then search.product.name
    searchProducts()

    vm.searchProducts = searchProducts
    vm.categoryParentGroup = categoryParentGroup
    vm.cancel = cancel
    vm.selectProduct = selectProduct
    return
