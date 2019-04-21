angular.module 'stock'
.controller 'WorksController', ($scope) ->
    'ngInject'
    vm = this

    return
.controller 'WorksListController', (RequestService, $scope, $uibModal, $translate, $state) ->
    'ngInject'
    vm = this
    vm.offset = 0
    vm.limit = 10

    vm.worksGridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs: [
            {displayName: 'Наименование', name: 'theme.name', headerCellFilter: 'translate'}
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_work = angular.copy row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getWorks()
                return

    getWorks =  ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        filter.offset = vm.offset
        filter.user_id = $scope.app.ua.id
        filter.with_related = true
        RequestService.post('documents.listing', filter).then (result) ->
            vm.works = result.docs
            vm.worksGridOptions.data = vm.works
            vm.worksGridOptions.totalItems = vm.works.length
            return
        return

    newWork = ()->
        $state.go('app.works.create')
        return

    showDiss= ->
        $state.go 'app.application.degree'
        return

    showWork = ->
        $state.go 'app.works.view', {works:vm.selected_work}

    vm.getWorks = getWorks
    vm.newWork = newWork
    vm.showWork = showWork
    vm.showDiss = showDiss

    getWorks()
    return
.controller 'WorksCreateController', (RequestService, $scope, $uibModal, $translate, $state) ->
    'ngInject'
    vm = this

    getTheme =  ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        filter.offset = vm.offset
        filter.user_id = $scope.app.ua.id
        filter.with_related = true
        RequestService.post('theme.listing', filter).then (result) ->
            vm.themes = result.docs
            return
        return

    saveDocument = ->
        vm.document.created_date = new Date()
        vm.document.user_id = $scope.app.ua.id
        RequestService.post('documents.save', vm.document)
        .then (response) ->
            $state.go 'app.works.list'
            toastr.success 'Тема диссертации создана'
        return

    goBack = ->
        $state.go 'app.works.list'
        return

    vm.getTheme = getTheme
    vm.saveDocument = saveDocument
    vm.goBack = goBack

    getTheme()
    return
.controller 'WorksDissovController', (RequestService, $scope, $uibModal, $translate, $state, $stateParams) ->
    'ngInject'
    vm = this
#    vm.theme = $stateParams.theme
#
#    if vm.theme is null || vm.theme is undefined
#        $state.go 'app.works.list'

    vm.dissGridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs: [
            {displayName: 'Шифр', name: 'code', width: 100}
            {displayName: 'На соискание ученой степени', name: 'academicdegree.name_ru', width: 150}
            {displayName: 'Отрасль науки', name: 'branchesofscience.name_ru', headerCellFilter: 'translate', width: 200}
            {displayName: 'Специальность', name: 'specialty.name_ru', headerCellFilter: 'translate'}
            {displayName: 'Организация', name: 'organization.name_ru'}
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_dissov = angular.copy row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getDiss()
                return

    getDiss =  ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        filter.filter.branchesofscience_id = vm.theme.branchesofscience_id
        filter.filter.academicdegree_id = vm.theme.academicdegree_id
        filter.filter.specialty_id = vm.theme.specialty_id
        filter.offset = vm.offset
        filter.with_related = true
        RequestService.post('dissov.listing', filter).then (result) ->
            vm.diss = result.docs
            vm.dissGridOptions.data = vm.diss
            vm.dissGridOptions.totalItems = vm.diss.length
            return
        return

    goBack = ->
        $state.go 'app.application.list'
        return

    vm.getDiss = getDiss
    vm.goBack = goBack

    getDiss()
    return
.controller 'WorksViewController', (RequestService, $scope, $uibModal, $translate, $state, $stateParams) ->
    'ngInject'
    vm = this
    vm.works = $stateParams.works

