angular.module 'stock'
.controller 'PersonsController', ($scope) ->
    'ngInject'
    vm = this
    return
.controller 'PersonsListController', (RequestService, $scope, $uibModal, $translate, $state) ->
    'ngInject'
    vm = this
    vm.offset = 0
    vm.limit = 20

    vm.usersGridOptions =
        noUnselect: true
        paginationPageSizes: [20, 100, 500]
        paginationPageSize: 20
        useExternalPagination: true
        columnDefs: [
            { displayName: 'id', name: 'id', headerCellFilter: 'translate', width:50}
            { displayName: 'Фамилия', name: 'last_name', headerCellFilter: 'translate'}
            { displayName: 'Имя', name: 'first_name', headerCellFilter: 'translate'}
            { displayName: 'Отчество', name: 'middle_name', headerCellFilter: 'translate'}
            { displayName: 'Дата рождения', name: 'birthday',  headerCellFilter: 'translate', type: 'date', cellFilter: 'amDateFormat:\'DD-MM-YYYY\''}
            { displayName: 'EMAIL_LABEL', name: 'email',  headerCellFilter: 'translate'}
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
        RequestService.post('user.listing',filter).then (result) ->
            vm.users = result.users
            vm.usersGridOptions.data = vm.users
            vm.usersGridOptions.totalItems = result.count
            return
        return

    editUser = (user_id)->
        $state.go 'app.persons.edit', {user: vm.selected_user}
        return

    showUser = ->
        $state.go('app.persons.view', {user: vm.selected_user})
        return

    newUser = ->
        employeeDialog = $uibModal.open
            templateUrl: 'app/users/create.html',
            controller: 'UsersEditController',
            controllerAs: 'user'
            size: 'lg'
            resolve:
                user: undefined
        employeeDialog.result.then ->
            getUsers()
        return


    vm.editUser = editUser
    vm.newUser = newUser
    vm.getUsers = getUsers
    vm.showUser = showUser

    getUsers()
    return
.controller 'PersonsViewController', ($rootScope,$base64, $scope, $state, RequestService, $uibModal, $uibModalStack, toastr, Session, flowFactory, $stateParams) ->
    'ngInject'
    vm = this
    if !$stateParams.user
        $state.go 'app.persons.list'
    vm.today = new Date()
    vm.user = $stateParams.user
    vm.education = null
    vm.work = null
    vm.degree = null
    vm.files = {}
    vm.filter = null

    getEducation = ->
        filter = {filter:{}}
        filter.filter.user_id = vm.user.id
        filter.with_related = true
        RequestService.post 'education.listing', filter
        .then (result) ->
            vm.educations = result.docs
            return

    getWork = ->
        filter = {filter:{}}
        filter.filter.user_id = vm.user.id
        filter.with_related = true
        RequestService.post 'work.listing', filter
        .then (result) ->
            vm.works = result.docs
            return


    getDegree = ->
        filter = {filter:{}}
        filter.filter.user_id = vm.user.id
        filter.with_related = true
        RequestService.post 'degree.listing', filter
        .then (result) ->
            vm.degrees = result.docs
            return


    getRank = ->
        filter = {filter:{}}
        filter.filter.user_id = vm.user.id
        filter.with_related = true
        RequestService.post 'rank.listing', filter
        .then (result) ->
            vm.ranks = result.docs
            return


    vm.getEducation = getEducation
    vm.getWork = getWork
    vm.getDegree = getDegree
    vm.getRank = getRank

    getRank()
    getDegree()
    getEducation()
    getWork()
    return
.controller 'PersonsEditController', ($rootScope,$base64, $scope, $state, RequestService, $uibModal, $uibModalStack, toastr, Session, flowFactory, $stateParams) ->
    'ngInject'
    vm = this
    vm.profile = $stateParams.user
    vm.today = new Date()
    vm.education = null
    if !vm.profile
        $state.go 'app.persons.list'

    imageSelected = (event, $flow, flowFile)->
        if !flowFile.file.type.startsWith('image/')
            toastr.warning 'Выберите изображение'
            event.preventDefault()
            return false
        avatarModal = $uibModal.open
            templateUrl: 'app/profile/avatar.html'
            controller: 'AvatarEditController'
            controllerAs: 'avatar'
            size: 'lg'
            resolve:
                image: flowFile.file
        avatarModal.result.then (image)->
            $flow.cancel()
            RequestService.post 'upload/user/' + vm.profile.id, {file: image}
            .then (result)->
                vm.profile.data.image = 'image/' + result.file
                return
            return
        , (result)->
            $flow.cancel()
            return
        return


    putData = ->
        RequestService.post 'user.put', vm.profile
        .then (result) ->
            vm.profile = result.user
            Session.setUser(result.user)
            $scope.app.ua = Session.getUser()
            toastr.success 'Изменения сохранены'
            return

    openDatePicker = ->
        vm.datepicker_opened = !vm.datepicker_opened
        return

    getDegree = ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        filter.filter.user_id = vm.profile.id
        filter.with_related = true
        filter.order_by = ["_created DESC"]
        RequestService.post 'degree.listing', filter
        .then (result) ->
            vm.degrees = result.docs
            return

    putDataDegree = ->
        vm.degree.user_id =  vm.profile.id
        RequestService.post 'degree.save', vm.degree
        .then (result) ->
            vm.degree = null
            getDegree()
            toastr.success 'Изменения сохранены'
            return

    editDegree = (identity) ->
        vm.degree = identity
        return

    cancelDegree = () ->
        vm.degree = null
        return

    removeDegree = (item) ->
        RequestService.post('degree.delete', item)
        .then (data) ->
            getDegree()
            return


    confirmActionDegree = (degree)->
        editModal = $uibModal.open
            templateUrl: 'app/modals/confirmation-dialog.html'
            controller: 'ProfileDialogController'
            controllerAs: 'profile_dialog'
            size: 'sm'
            resolve:
                text: {text: ", что хотите удалить"}
        editModal.result.then((result)->
            if result
                removeDegree(degree)
            return
        )
        return

    getRank = ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        filter.filter.user_id = vm.profile.id
        filter.with_related = true
        filter.order_by = ["_created DESC"]
        RequestService.post 'rank.listing', filter
        .then (result) ->
            vm.ranks = result.docs
            return

    putDataRank = ->
        vm.rank.user_id =  vm.profile.id
        RequestService.post 'rank.save', vm.rank
        .then (result) ->
            vm.rank = null
            getRank()
            toastr.success 'Изменения сохранены'
            return

    editRank = (identity) ->
        vm.rank = identity
        return

    cancelRank = () ->
        vm.rank = null
        return

    removeRank = (item) ->
        RequestService.post('rank.delete', item)
        .then (data) ->
            getRank()
            return


    confirmActionRank = (rank)->
        editModal = $uibModal.open
            templateUrl: 'app/modals/confirmation-dialog.html'
            controller: 'ProfileDialogController'
            controllerAs: 'profile_dialog'
            size: 'sm'
            resolve:
                text: {text: ", что хотите удалить"}
        editModal.result.then((result)->
            if result
                removeRank(rank)
            return
        )
        return

    vm.imageSelected = imageSelected
    vm.putData = putData
    vm.openDatePicker = openDatePicker
    vm.confirmActionDegree = confirmActionDegree
    vm.getDegree = getDegree
    vm.putDataDegree = putDataDegree
    vm.editDegree = editDegree
    vm.cancelDegree = cancelDegree
    vm.removeDegree = removeDegree
    vm.getRank = getRank
    vm.putDataRank = putDataRank
    vm.editRank = editRank
    vm.cancelRank = cancelRank
    vm.removeRank = removeRank
    vm.confirmActionRank = confirmActionRank


    getRank()
    getDegree()
    return
