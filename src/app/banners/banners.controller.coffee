angular.module 'stock'
.controller 'BannersController', ($timeout, toastr, $translate, $rootScope,$http,$state) ->
    'ngInject'
    vm = this

    return

.controller 'BannersListController', ($rootScope, $scope, $state, RequestService, $http, $translate) ->
    'ngInject'
    vm = this
    vm.searchValues = {}
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
                displayName: 'LINK_LABEL', name: 'link', headerCellFilter: 'translate'
            }
            {
                displayName: 'DATE_CREATION_LABEL_FROM', name: '_created', headerCellFilter: 'translate'
            }
            {
                displayName: 'DATE_CREATION_LABEL_TO', name: '_deleted', headerCellFilter: 'translate'
            }
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_banners = angular.copy row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getBanners()
                return

    getBanners = () ->
        filters = vm.searchValues
        RequestService.post('banners/listing', filters)
        .then((response) ->
            vm.gridOptions.data = response.docs
            return
        (response) ->
            return)
        return


    openCreateForm = ->
        $state.go('app.banners.form')
        return

    openEditForm = ->
        $state.go 'app.banners.form', {banners:vm.selected_banners}


    removeBanners = ->
        return if not vm.selected_banners
        vm.selected_banners.crud = 'Banners'
        RequestService.post 'banners/remove', vm.selected_banners
        .then (result) ->
            getBanners()
            return
        return

    vm.removeBanners = removeBanners
    vm.getBanners = getBanners
    vm.openCreateForm = openCreateForm
    vm.openEditForm = openEditForm
    getBanners()
    
    return
.controller 'BannersFormController', ($rootScope, $scope, $state, $stateParams, RequestService, $http, hotkeys, db, Session, AppStorage, toastr, $base64, $uibModal) ->
    'ngInject'
    vm = this
    vm.bannersItem = $stateParams.banners

    saveBanners = ->
        RequestService.post('banners/put', vm.bannersItem)
        .then((response) ->
            goBack()
            return
        (response) ->
            return)
        return

    goBack = ->
        $state.go('app.banners.list')
        return

    vm.saveBanners = saveBanners
    vm.goBack = goBack

    return

