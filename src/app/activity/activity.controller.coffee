angular.module 'stock'
.controller 'ActivityController', ($timeout, toastr, $translate, RequestService, $rootScope,$http,$state) ->
    'ngInject'
    vm = this

    changeLanguage = (langCode) ->
        $translate.use(langCode)
        return

    getView = (formview)->
        vm.template = "app/docs/#{formview}/view.html"
        return

    vm.changeLanguage = changeLanguage
    vm.getView = getView

    return

.controller 'ActivityAspirantController', ($timeout, toastr, $translate, RequestService, $stateParams,$http,$state) ->
    'ngInject'
    vm = this

    vm.offset = 0
    vm.limit = 50
    vm.usersGridOptions =
        noUnselect: true
        paginationPageSizes: [50, 100, 500]
        paginationPageSize: 50
        useExternalPagination: true
        columnDefs: [
            { displayName: 'id', name: 'id', headerCellFilter: 'translate', width:50}
            { displayName: 'Фамилия', name: 'last_name', headerCellFilter: 'translate'}
            { displayName: 'Имя', name: 'first_name', headerCellFilter: 'translate'}
            { displayName: 'Отчество', name: 'middle_name', headerCellFilter: 'translate'}
            {displayName: 'Дата рождения', name: 'birthday',  headerCellFilter: 'translate', type: 'date', cellFilter: 'amDateFormat:\'DD-MM-YYYY\''}
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_user = angular.copy row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getUsers()
                return

    getUsers =  ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        for k,v of vm.filter
            if k == "first_name"
                filter.filter.first_name = v
            if k == "last_name"
                filter.filter.last_name = v
            if k == "middle_name"
                filter.filter.middle_name = v
        filter.offset = vm.offset
        filter.limit = vm.limit
        filter.with_related = true
        filter.crud = 'User'
        RequestService.post('user/listing',filter).then (result) ->
            vm.users = result.users
            vm.usersGridOptions.data = result.users
            vm.usersGridOptions.totalItems = result.count
            return
        return
    showUsers = ->
        $state.go 'person', {person: vm.selected_user}


    changeLanguage = (langCode) ->
        $translate.use(langCode)
        return
    vm.showUsers=showUsers
    vm.changeLanguage = changeLanguage
    vm.getUsers = getUsers
    getUsers()

    return

.controller 'ActivityViewController', ($timeout, toastr, $translate, RequestService, $stateParams,$http,$state) ->
    'ngInject'
    vm = this

    vm.offset = 0
    vm.limit = 50
    vm.usersGridOptions =
        noUnselect: true
        paginationPageSizes: [50, 100, 500]
        paginationPageSize: 50
        useExternalPagination: true
        columnDefs: [
            { displayName: 'id', name: 'id', headerCellFilter: 'translate', width:50}
            { displayName: 'Фамилия', name: 'last_name', headerCellFilter: 'translate'}
            { displayName: 'Имя', name: 'first_name', headerCellFilter: 'translate'}
            { displayName: 'Отчество', name: 'middle_name', headerCellFilter: 'translate'}
            {displayName: 'Дата рождения', name: 'birthday',  headerCellFilter: 'translate', type: 'date', cellFilter: 'amDateFormat:\'DD-MM-YYYY\''}
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_user = angular.copy row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getUsers()
                return

    getUsers =  ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        for k,v of vm.filter
            if k == "first_name"
                filter.filter.first_name = v
            if k == "last_name"
                filter.filter.last_name = v
            if k == "middle_name"
                filter.filter.middle_name = v
        filter.offset = vm.offset
        filter.limit = vm.limit
        filter.with_related = true
        filter.crud = 'User'
        RequestService.post('user/listing',filter).then (result) ->
            vm.users = result.users
            vm.usersGridOptions.data = result.users
            vm.usersGridOptions.totalItems = result.count
            return
        return
    showUsers = ->
        $state.go 'person', {person: vm.selected_user}


    changeLanguage = (langCode) ->
        $translate.use(langCode)
        return
    vm.showUsers=showUsers
    vm.changeLanguage = changeLanguage
    vm.getUsers = getUsers
    getUsers()

    return
.controller 'ActivityDissovController', ($timeout, toastr, $translate, RequestService, $stateParams,$http,$state) ->
    'ngInject'
    vm = this

    getDiss =  ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        filter.offset = vm.offset
        filter.with_related = true
        RequestService.post('dissov/listing', filter).then (result) ->
            vm.diss = result.docs
            vm.totalItems = vm.diss.length
        return

    showDiss =(work) ->
        $state.go 'dissov_view', {disscouncil: work}

    vm.showDiss = showDiss
    vm.getDiss = getDiss

    getDiss()
    return

.controller 'ActivityDissovViewController', (RequestService, $scope, $stateParams, $uibModal, $translate, $state) ->
    'ngInject'
    vm = this

    vm.go = (path, data) ->
        $state.go path, data

    vm.diss = $stateParams.disscouncil
    console.log vm.diss

    if Object.keys(vm.diss).length == 0
        vm.go('view')
        return

    vm.diss.date_start = new Date(vm.diss.date_start)
    vm.diss.date_end = new Date(vm.diss.date_end)

    return
.controller 'ActivityPersonView', (RequestService, $scope, $stateParams,$uibModal, $translate, $state) ->
    'ngInject'
    vm = this
    vm.today = new Date()
    vm.person = $stateParams.person
    vm.education = null
    vm.work = null
    vm.degree = null
    vm.files = {}
    vm.filter = null

    getRank = ->
        filter = {filter:{}}
        filter.filter.user_id = vm.person.id
        filter.with_related = true
        RequestService.post 'rank.listing', filter
        .then (result) ->
            vm.ranks = result.docs
            return
    getDegree = ->
        filter = {filter:{}}
        filter.filter.user_id = vm.person.id
        filter.with_related = true
        RequestService.post 'degree.listing', filter
        .then (result) ->
            vm.degrees = result.docs
            return

    vm.getRank = getRank
    vm.getDegree=getDegree

    getRank()
    getDegree()

    return
