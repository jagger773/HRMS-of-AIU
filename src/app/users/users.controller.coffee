angular.module 'stock'
.controller 'UsersController', (RequestService, $scope, $uibModal, $http) ->
    'ngInject'
    vm = this
    vm.offset = 0
    vm.limit = 10
    vm.putusers = {}

    vm.usersGridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs: [
            {name: 'email', displayName: 'Емайл'}
            {name: 'role', displayName: 'Важность'}
            {name: 'rec_date', displayName: 'Дата регистрации',type: 'date', cellFilter: 'amDateFormat:\'DD-MM-YYYY\''}
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
            if k == "username"
                filter.filter.username = v
            if k == "email"
                filter.filter.email = v
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
            vm.usersGridOptions.totalItems = vm.users.length
            console.log(vm.users)
            return
        return

    editUser = ->
        employeeDialog = $uibModal.open
            templateUrl: 'app/users/edit.html',
            controller: 'UsersEditController',
            controllerAs: 'user'
            size: 'lg'
            resolve:
                user: angular.copy vm.selected_user
        employeeDialog.result.then ->
            getUsers()
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

#    saveUsers = ->
#        $http.get('assets/json/users.json').success (response) ->
#            vm.putusers.items = response
#            RequestService.post('user.putusers', vm.putusers).then (result) ->
#        return

    vm.editUser = editUser
    vm.newUser = newUser
    vm.getUsers = getUsers
#    vm.saveUsers = saveUsers

    getUsers()
    return

.controller 'UsersEditController', (RequestService, user, $scope, $uibModalInstance) ->
    'ngInject'
    vm = this

    if user is null or user is undefined
        vm.user = {}
    else
        vm.user = user

    createUser = ->
        RequestService.post('user.register', vm.user).then (result) ->
            console.log("createUser ->result.token = "+result.token)
            $uibModalInstance.close result
            return
        return


    updateUser = ->
        RequestService.post('user.put', vm.user).then (result) ->
            console.log("updateUser ->result.user = ")
            console.log(result.user)
            $uibModalInstance.close result
            return
        return

    cancel = ->
        $uibModalInstance.dismiss 'cancel'
        return

    vm.updateUser = updateUser
    vm.createUser = createUser
    vm.cancel = cancel

    return
