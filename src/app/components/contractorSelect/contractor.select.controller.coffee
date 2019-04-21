angular.module 'stock'
.constant 'stockContractorModalOptions', {
    title: 'Выбрать контрагента'
    can_create: false
    filter: {}
}
.controller 'ContractorSelectController', ($scope, RequestService, $uibModalInstance, modalOptions, stockContractorModalOptions, $uibModal) ->
    'ngInject'
    vm = this

    vm.modalOptions = angular.merge {}, stockContractorModalOptions, angular.copy(modalOptions || {})

    vm.offset = 0
    vm.limit = 10
    vm.gridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        appScopeProvider:
            onDoubleClick: (row) ->
                selectContractor(row.entity)
        rowTemplate: '<div ng-dblclick="grid.appScope.onDoubleClick(row)" ng-repeat="col in colContainer.renderedColumns" class="ui-grid-cell" ui-grid-cell></div>'
        columnDefs: [
            {name: 'name', displayName: 'Наименование'}
            {name: 'data.email', displayName: 'E-mail'}
            {name: 'data.industry.name', displayName: 'Индустрия'}
            {name: 'contractor_type_value.data.name', displayName: 'Тип'}
            {name: 'contractor_company.name', displayName: 'Компания агента', visible: false}
        ]
        events:
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                searchContractors(true)
                return
            onRowSelect: (row) ->
                vm.selected_contractor = angular.copy row.entity
                return

    searchContractors = (paging)->
        if !paging || angular.isUndefined paging
            vm.offset = 0
        filter =
            offset: vm.offset
            limit: vm.limit
            with_related: true
            search: vm.search_name
            filter:
                contractor_type: vm.modalOptions.filter.contractor_type or vm.contractor_type
                data:
                    industry_id: vm.industry_id
        RequestService.post 'contractor.list', filter
        .then (result)->
            delete vm.selected_contractor
            vm.gridOptions.data = result.docs
            vm.gridOptions.totalItems = result.count
            return
        return

    industryParentGroup = (item) ->
        if !item.parent
            return ''
        return item.parent.name

    cancel = ->
        $uibModalInstance.dismiss 'cancel'
        return

    selectContractor = (selected_contractor) ->
        if selected_contractor
            $uibModalInstance.close selected_contractor
        else if angular.isDefined vm.selected_contractor
            $uibModalInstance.close vm.selected_contractor
        return

    createContractor = ->
        editModal = $uibModal.open
            templateUrl: 'app/contractor/edit.html'
            controller: 'ContractorEditController'
            controllerAs: 'contractor'
            size: 'lg'
            scope: $scope
            resolve:
                contractor: undefined

        editModal.result.then ->
            searchContractors()
        return

    searchContractors()

    vm.searchContractors = searchContractors
    vm.industryParentGroup = industryParentGroup
    vm.cancel = cancel
    vm.selectContractor = selectContractor
    vm.createContractor = createContractor
    return
