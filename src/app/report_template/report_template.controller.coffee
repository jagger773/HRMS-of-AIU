angular.module 'stock'
.controller 'Report_templateController', ($scope, RequestService, $uibModal, $state) ->
    vm = this

    vm.template_page = 0
    vm.template_limit = 10
    vm.query_page = 0
    vm.query_limit = 10

    vm.gridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs: [
            {
                field: 'company.name'
                displayName: 'Компания'
            }
            {
                field: 'code'
                displayName: 'Код'
            }
            {
                field: 'name'
                displayName: 'Наименование'
            }
            {
                field: 'report_category.name'
                displayName: 'Категория'
            }
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_template = row.entity
                return
            onPageSelect: (page, size) ->
                vm.template_page = page
                vm.template_limit = size
                getTemplates()
                return
    vm.queriesGridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs: [
            {
                field: 'code'
                displayName: 'Код'
            }
            {
                field: 'name'
                displayName: 'Наименование'
            }
            {
                field: 'result_key'
                displayName: 'Ключ возврата'
            }
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_query = row.entity
                return
            onPageSelect: (page, size) ->
                vm.query_page = page
                vm.query_limit = size
                getQueries()
                return

    getTemplates = ->
        filter =
            offset: vm.template_page * vm.template_limit
            limit: vm.template_limit
            with_related: ['report_category']
        RequestService.post 'report.listing', filter
        .then (data) ->
            delete vm.selected_template
            vm.gridOptions.data = data.report_list
            vm.gridOptions.totalItems = data.count

    editTemplate = ->
        $state.go 'app.report_designer', {id:vm.selected_template._id}

    getQueries = ->
        filter =
            offset: vm.query_page * vm.query_limit
            limit: vm.query_limit
        RequestService.post 'report.query_listing', filter
        .then (data) ->
            delete vm.selected_query
            vm.queriesGridOptions.data = data.docs
            vm.queriesGridOptions.totalItems = data.count

    newQuery = ->
        editModal = $uibModal.open
            templateUrl: 'app/report_template/query_edit.html'
            controller: 'ReportQueryEditController'
            controllerAs: 'edit'
            size: 'lg'
            scope: $scope
            resolve:
                report_query: null
        editModal.result.then ->
            getQueries()

    editQuery = ->
        editModal = $uibModal.open
            templateUrl: 'app/report_template/query_edit.html'
            controller: 'ReportQueryEditController'
            controllerAs: 'edit'
            size: 'lg'
            scope: $scope
            resolve:
                report_query: vm.selected_query
        editModal.result.then ->
            delete vm.selected_query
            getQueries()


    vm.getTemplates = getTemplates
    vm.editTemplate = editTemplate

    vm.getQueries = getQueries
    vm.newQuery = newQuery
    vm.editQuery = editQuery

    getTemplates()
    getQueries()
    return
