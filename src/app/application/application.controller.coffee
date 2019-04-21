angular.module 'stock'
.controller 'ApplicationController', ($scope)->
    'ngInject'
    vm = this
    return
.controller 'ApplicationListController', (RequestService, $scope, $uibModal, $translate, $state)->
    'ngInject'
    vm = this

    vm.applicationsGridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs: [
            {displayName: 'Дата подачи', name: 'date_app',type: 'date', cellFilter: 'date:\'yyyy-MM-dd\''}
            {displayName: 'Статус', name: 'status', headerCellFilter: 'translate'}
            {displayName: 'Дисс Совет', name: 'dissov.code', headerCellFilter: 'translate'}
            {displayName: 'На соискание ученой степени', name: 'academicdegree.name_ru', headerCellFilter: 'translate'}
            {displayName: 'Отрасль науки', name: 'branchesofscience.name_ru', headerCellFilter: 'translate'}
            {displayName: 'Специальность', name: 'specialty.name_ru', headerCellFilter: 'translate'}
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_application = angular.copy row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getApplications()
                return

    getApplications =  ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        filter.offset = vm.offset
        filter.with_related = true
        RequestService.post('disapplication.listing', filter).then (result) ->
            vm.application = result.docs
            vm.applicationsGridOptions.data = vm.application
            vm.applicationsGridOptions.totalItems = vm.application.length
            return
        return

    showDiss= ->
        $state.go 'app.application.dissov'
        return

    vm.showDiss = showDiss
    vm.getApplications = getApplications

    getApplications()
    return
.controller 'ApplicationDissovController', (RequestService, $scope, $uibModal, $translate, $state)->
    'ngInject'
    vm = this
    return
.controller 'ApplicationDegreeController', (RequestService, toastr, $scope, $uibModal, $translate, $state)->
    'ngInject'
    vm = this
    vm.application = {}
    getTheme =  ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        filter.filter.user_id = $scope.app.ua.id
        filter.offset = vm.offset
        filter.with_related = true
        RequestService.post('theme.listing', filter).then (result) ->
            vm.themes = result.docs
            return
        return

    getDiss =  ->
        vm.academicdegree = vm.theme.academicdegree
        vm.specialty = vm.theme.specialty
        vm.branchesofscience = vm.theme.branchesofscience
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        filter.offset = vm.offset
        filter.with_related = true
        RequestService.post('dissov.listing', filter).then (result) ->
            vm.diss = result.docs
            return
        return

    saveApp = (dissId) ->
        vm.application.dissov_id = dissId
        vm.application.theme_id = vm.theme._id
        RequestService.post('disapplication.save', vm.application).then (result) ->
            $state.go 'app.application.list'
            toastr.success 'Заявка отправлена!'
            return
        return

    goBack = ->
        $state.go 'app.application.dissov'
        return

    vm.getTheme = getTheme
    vm.goBack = goBack
    vm.getDiss = getDiss
    vm.saveApp = saveApp

    getTheme()
    return
.controller 'ApplicationRankController', (RequestService, $scope, $uibModal, $translate, $state)->
    'ngInject'
    vm = this
    return
