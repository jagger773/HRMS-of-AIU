angular.module 'stock'
.controller 'RejecteddissController', ($timeout, toastr, $translate, $rootScope,$http,$state) ->
    'ngInject'

    return

.controller 'RejecteddissListController', ($rootScope, $scope, $state, RequestService, $http, $translate) ->
    'ngInject'
    vm = this
    vm.searchValues = {}
    vm.searchValuesLang = {}
    vm.dateOptions =
        startingDay: 1
        opened1: false
        opened2: false

    vm.gridOptions =
        noUnselect: true
        paginationPageSizes: [100, 200, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs:[
            {
                displayName: 'ФИО научного руководителя', name: 'name_ru', headerCellFilter: 'translate'
            }
            {
                displayName: 'дата отклонения', name: 'name_kg', headerCellFilter: 'translate'
            }
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_regulations = angular.copy row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getRegulations()
                return

    getRegulations = () ->
        vm.searchValues.lang =  $translate.use().valueOf()
        lang = vm.searchValuesLang
        filters = vm.searchValues
        RequestService.post('regulations/listing', filters,lang)
        .then((response) ->
            vm.gridOptions.data = response.list
            return
        (response) ->
            return)
        return

    openCreateForm = ->
        $state.go('app.rejecteddiss.form')
        return

    openEditForm = ->
        $state.go 'app.rejecteddiss.form', {regulations:vm.selected_regulations}

    removeRegulations = ->
        return if not vm.selected_regulations
        vm.selected_regulations.crud = 'Regulations'
        RequestService.post 'regulations/remove', vm.selected_regulations
        .then (result) ->
            getRegulations()
            return
        return
#    vm.removeRegulations = removeRegulations
#    vm.getRegulations = getRegulations
    vm.openCreateForm = openCreateForm
    vm.openEditForm = openEditForm
#    getRegulations()

    return
.controller 'RejecteddissFormController', ($rootScope, $scope, $state, $stateParams, RequestService, $http) ->
    'ngInject'
    vm = this
    vm.regulationsItem = $stateParams.regulations

    getDepartments = ->
        RequestService.post('departments/listing').then (result) ->
            vm.departments = result.docs
        return


    saveRegulations = ->
        RequestService.post('regulations/put', vm.regulationsItem)
        .then((response) ->
            goBack()
            return
        (response) ->
            return)
        return


    goBack =  ->
        $state.go('app.rejecteddiss.list')
        return


#    vm.getDepartments = getDepartments
#    vm.saveRegulations = saveRegulations
    vm.goBack = goBack
#    getDepartments()

    return
