angular.module 'stock'
.controller 'ThemeController', ($scope) ->
    'ngInject'
    vm = this
    return
.controller 'ThemeListController', (RequestService, $scope, $uibModal, $translate, $state) ->
    'ngInject'
    vm = this
    vm.offset = 0
    vm.limit = 10

    vm.themesGridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs: [
            {displayName: 'Название', name: 'name'}
            {name: 'last_name', displayName: 'Соискатель', cellTemplate: '<span>{{row.entity.last_name}} {{row.entity.first_name}}</span>', width:180}
            {displayName: 'На соискание ученой степени', name: 'academicdegree.name_ru', width:150}
            {displayName: 'Отрасль науки', name: 'branchesofscience.name_ru', width:150}
            {displayName: 'Дата утверждения', name: 'approval_date', type: 'date', cellFilter: 'amDateFormat:\'DD-MM-YYYY\', width:100'}
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_theme = angular.copy row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getThemes()
                return

    getThemes =  ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        for k,v of vm.filter
            if k == "status"
                if v == "Все"
                    if filter.filter.data
                        delete filter.filter.data
                    continue
                else
                    filter.filter.data = {status:v}
            if k == "academicdegree_id"
                filter.filter.academicdegree_id = v
            if k == "branchesofscience_id"
                filter.filter.branchesofscience_id = v
            if k == "specialty_id"
                filter.filter.specialty_id = v
            if k == "organization_id"
                filter.filter.organization_id = v
            if k == "name"
                filter.filter.user_name = v
            if k == "surname"
                filter.filter.user_surname = v
        filter.offset = vm.offset
        filter.limit = vm.limit
        filter.with_related = true
        filter.order_by = ["_created DESC"]
        RequestService.post('theme.listing', filter).then (result) ->
            vm.themes = result.docs
            vm.themesGridOptions.data = vm.themes
            vm.themesGridOptions.totalItems = vm.themes.length
            return
        return

    newTheme = ()->
        $state.go('app.theme.create')
        return

    editTheme = ()->
        $state.go('app.theme.edit', {theme: vm.selected_theme})
        return



    vm.getThemes = getThemes
    vm.newTheme = newTheme
    vm.editTheme = editTheme

    getThemes()
    return
.controller 'ThemeCreateController', (RequestService, $scope, $uibModal, toastr, $state) ->
    'ngInject'
    vm = this

    saveTheme = ->
        RequestService.post('theme.save', vm.theme)
        .then (response) ->
            $state.go 'app.theme.list'
            toastr.success 'Тема диссертации создана'
        return

    goBack = ->
        $state.go 'app.theme.list'
        return

    vm.refspecialty = null
    addRefspecialty = ->
        if vm.refspecialties is null || vm.refspecialties is undefined
            vm.refspecialties = []
        else
            if vm.refspecialties.includes(vm.refspecialty)
                toastr.warning("This element is already in list ! ! !")
                return

        if vm.refspecialty isnt null and vm.refspecialty isnt undefined and vm.refspecialty isnt ''
            vm.refspecialties.push({
                code: vm.refspecialty.code
                specialty_id: vm.refspecialty._id
            })
            vm.refspecialty = null
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deleteRefspecialty = (index) ->
        vm.refspecialties.splice(index,1)
        return

    vm.workspecialty = null
    addWorkspecialty = ->
        if vm.workspecialties is null || vm.workspecialties is undefined
            vm.workspecialties = []
        else
            if vm.workspecialties.includes(vm.workspecialty)
                toastr.warning("This element is already in list ! ! !")
                return

        if vm.workspecialty isnt null and vm.workspecialty isnt undefined and vm.workspecialty isnt ''
            vm.workspecialties.push({
                code: vm.workspecialty.code
                specialty_id: vm.workspecialty._id
            })
            vm.workspecialty = null
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deleteWorkspecialty = (index) ->
        vm.workspecialties.splice(index,1)
        return

    getUsers = ->
        employeeDialog = $uibModal.open
            templateUrl: 'app/theme/users.html',
            controller: 'ThemeUsersController',
            controllerAs: 'user'
            size: 'lg'
        employeeDialog.result.then (row)->
            vm.theme.last_name = row.result.last_name
            vm.theme.first_name = row.result.first_name
            vm.theme.middle_name = row.result.middle_name
        return

    vm.addWorkspecialty = addWorkspecialty
    vm.deleteWorkspecialty = deleteWorkspecialty
    vm.addRefspecialty = addRefspecialty
    vm.deleteRefspecialty = deleteRefspecialty
    vm.saveTheme = saveTheme
    vm.getUsers = getUsers
    vm.goBack = goBack

#    getUsers()
    return
.controller 'ThemeEditController', (RequestService, $scope, $uibModal, toastr, $state, $stateParams) ->
    'ngInject'
    vm = this
    vm.theme = $stateParams.theme
    console.log(vm.theme)

    getUsers =  ->
        RequestService.post('user.listing',{}).then (result) ->
            vm.users = result.users
            return
        return

    saveTheme = ->
        RequestService.post('theme.save', vm.theme)
        .then (response) ->
            $state.go 'app.theme.list'
            toastr.success 'Тема диссертации создана'
        return

    goBack = ->
        $state.go 'app.theme.list'
        return
    vm.goBack = goBack
    vm.saveTheme = saveTheme
    vm.getUsers = getUsers

    getUsers()
    return
.controller 'ThemeUsersController', (RequestService, $scope, $uibModal, toastr, $state, $uibModalInstance) ->
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
        filter.crud = 'User'
        RequestService.post('user/listing',filter).then (result) ->
            vm.users = result.users
            vm.usersGridOptions.data = result.users
            vm.usersGridOptions.totalItems = result.count
            return
        return

    goBack = ->
        $state.go 'app.theme.list'
        return

    add = (row) ->
        $uibModalInstance.close({result: vm.selected_user})

    vm.cancel = ->
        $uibModalInstance.dismiss 'cancel'
        return

    vm.add = add
    vm.goBack = goBack
    vm.getUsers = getUsers

    getUsers()
    return
