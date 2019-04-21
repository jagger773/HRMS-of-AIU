angular.module 'stock'
.controller 'UserworkController', ($rootScope, $scope, $state, RequestService) ->
    'ngInject'
    return
.controller 'UserworkListController', ($rootScope, $scope, $state, RequestService, $translate) ->
    'ngInject'
    vm = this
    vm.journals = []
    vm.offset = 0
    vm.limit = 20

    vm.userworkGridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs: [
            { displayName: 'Начало', name: 'date_start', headerCellFilter: 'translate', type: 'date', cellFilter: 'amDateFormat:\'DD-MM-YYYY\'', width:150}
            { displayName: 'Конец', name: 'date_end', headerCellFilter: 'translate', type: 'date', cellFilter: 'amDateFormat:\'DD-MM-YYYY\'', width:150}
            { displayName: 'Организация', name: 'org_name', headerCellFilter: 'translate'}
            { displayName: 'Должность', name: 'pos_name', headerCellFilter: 'translate'}
            { displayName: 'Страна', name: 'country.name_ru', headerCellFilter: 'translate'}
            { displayName: 'Город', name: 'city', headerCellFilter: 'translate'}
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_userwork = angular.copy row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getUserWorks()
                return

    getUserWorks = () ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        filter.user_id = $scope.app.ua.id
        filter.with_related = true
        filter.limit = vm.limit
        filter.offset = vm.offset
        RequestService.post('work.listing', filter)
        .then (response) ->
            vm.userworks = response.docs
            vm.userworkGridOptions.data = vm.userworks
            vm.userworkGridOptions.totalItems = vm.userworks.length
            return
        return

    newUserWork = ->
        $state.go 'app.userwork.edit', {userwork:vm.selected_userwork}
        return

    editUserWork = (identity) ->
        $state.go 'app.userwork.edit', {userwork:vm.selected_userwork}
        return

    removeWork = (index) ->
        vm.works.splice index, 1
        return

    deleteWork = (item)->
        RequestService.post('work.delete', item)
        .then (data) ->
            getWork()
            return

    confirmActionWork = (Work)->
        editModal = $uibModal.open
            templateUrl: 'app/modals/confirmation-dialog.html'
            controller: 'ProfileDialogController'
            controllerAs: 'profile_dialog'
            size: 'sm'
            resolve:
                text: {text: ", что хотите удалить"}
        editModal.result.then((result)->
            if result
                deleteWork(Work)
            return
        )
        return
    vm.getUserWorks = getUserWorks
    vm.newUserWork = newUserWork
    vm.confirmActionWork = confirmActionWork
    vm.removeWork = removeWork
    vm.editUserWork = editUserWork

    getUserWorks()
    return
.controller 'UserworkEditController', ($rootScope,$base64, $scope, $state, RequestService, toastr, Session, flowFactory, $stateParams) ->
    'ngInject'
    vm = this
    vm.userwork = {
        user_id: $scope.app.ua.id
    }
    if $stateParams.userwork
        vm.userwork = $stateParams.userwork

    putDataWork = ->
        RequestService.post 'work.save', vm.userwork
        .then (result) ->
            vm.userwork = null
            toastr.success 'Изменения сохранены'
            $state.go 'app.userwork.list'
            return

    cancelWork = () ->
        $state.go 'app.userwork.list'
        vm.userwork = null
        return

    vm.putDataWork = putDataWork
    vm.cancelWork = cancelWork

    return
