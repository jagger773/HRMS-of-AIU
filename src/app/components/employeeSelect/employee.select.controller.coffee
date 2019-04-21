angular.module 'stock'
.constant 'stockEmpModalOptions', {
    filter: {}
}
.controller 'EmployeeSelectController', ($scope, RequestService, $uibModalInstance, stockEmpModalOptions, modalOptions) ->
    'ngInject'
    vm = this
    vm.desabled_role = true

    vm.modalOptions = angular.merge {}, stockEmpModalOptions, angular.copy modalOptions
    if vm.modalOptions.filter.roles
        vm.role_id  = vm.modalOptions.filter.roles
        vm.desabled_role = false

    vm.offset = 0
    vm.limit = 10
    vm.gridOptions =
        noUnselect: true
        paginationPageSizes: [vm.limit, 100, 500]
        paginationPageSize: vm.limit
        useExternalPagination: true
        appScopeProvider:
            onDoubleClick: (row) ->
                selectEmployee(row.entity)
        rowTemplate: '<div ng-dblclick="grid.appScope.onDoubleClick(row)" ng-repeat="col in colContainer.renderedColumns" class="ui-grid-cell" ui-grid-cell></div>'
        columnDefs: [
            {name: 'user_id', displayName: 'ID'}
            {name: 'user.username', displayName: 'Имя пользователя'}
            {name: 'user.email', displayName: 'E-mail'}
            {name: 'access_value.data.name', displayName: 'Доступ'}
            {name: 'branches', displayName: 'Филиалы', visible: false, cellTemplate: '<div class="ui-grid-cell-contents"><span ng-repeat="branch in grid.getCellValue(row,col)">{{branch.name}}{{!$last?", ":""}}</span></div>'}
            {name: 'roles', displayName: 'Роли', cellTemplate: '<div class="ui-grid-cell-contents"><span ng-repeat="role in grid.getCellValue(row,col)">{{role.name}}{{!$last?", ":""}}</span></div>'}
        ]
        events:
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                searchEmployees(true)
                return
            onRowSelect: (row) ->
                vm.selected_employee = angular.copy row.entity
                return

    searchEmployees = (paging)->
        if !paging || angular.isUndefined paging
            vm.offset = 0
        filter =
            offset: vm.offset
            limit: vm.limit
            username: vm.search_name
            role_id: vm.role_id
            branch_id: vm.branch_id
            with_related: true
            filter:
                access: vm.access
        RequestService.post 'company.employees', filter
        .then (result)->
            delete vm.selected_employee
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

    selectEmployee = (selected_employee) ->
        if selected_employee
            $uibModalInstance.close selected_employee
        else if angular.isDefined vm.selected_employee
            $uibModalInstance.close vm.selected_employee
        return

    searchEmployees()

    vm.searchEmployees = searchEmployees
    vm.categoryParentGroup = categoryParentGroup
    vm.cancel = cancel
    vm.selectEmployee = selectEmployee
    return
