angular.module 'stock'
.controller 'UsereducationController', ($rootScope, $scope, $state, RequestService) ->
    'ngInject'
    return
.controller 'UsereducationListController', ($rootScope, $scope, $state, RequestService, $uibModal, $translate) ->
    'ngInject'
    vm = this
    vm.journals = []
    vm.offset = 0
    vm.limit = 20

    vm.usereducationGridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs: [
            { displayName: 'Начало', name: 'date_start', headerCellFilter: 'translate', type: 'date', cellFilter: 'amDateFormat:\'DD-MM-YYYY\'', width:150}
            { displayName: 'Конец', name: 'date_end', headerCellFilter: 'translate', type: 'date', cellFilter: 'amDateFormat:\'DD-MM-YYYY\'', width:150}
            { displayName: 'Организация', name: 'org_name', headerCellFilter: 'translate'}
            { displayName: 'Специальность', name: 'faculty', headerCellFilter: 'translate'}
            { displayName: 'Страна', name: 'country.name_ru', headerCellFilter: 'translate'}
            { displayName: 'Вид обучения', name: 'typeofgraduate.name_ru', headerCellFilter: 'translate'}
            { displayName: 'Форма обучения', name: 'typeoftraining.name_ru', headerCellFilter: 'translate'}
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_usereducation = angular.copy row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getUserEducations()
                return

    getUserEducations = () ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        filter.user_id = $scope.app.ua.id
        filter.with_related = true
        filter.limit = vm.limit
        filter.offset = vm.offset
        RequestService.post('education.listing', filter)
        .then (response) ->
            vm.usereducations = response.docs
            vm.usereducationGridOptions.data = vm.usereducations
            vm.usereducationGridOptions.totalItems = vm.usereducations.length
            return
        return

    newUserEducation = ->
        $state.go 'app.usereducation.edit', {usereducation:vm.selected_usereducation}
        return

    editUserEducation = (identity) ->
        $state.go 'app.usereducation.edit', {usereducation:vm.selected_usereducation}
        return

    removeWork = (index) ->
        vm.works.splice index, 1
        return

    deleteWork = (item)->
        RequestService.post('education.delete', item)
        .then (data) ->
            getWork()
            return

    confirmActionWork = (education)->
        editModal = $uibModal.open
            templateUrl: 'app/modals/confirmation-dialog.html'
            controller: 'ProfileDialogController'
            controllerAs: 'profile_dialog'
            size: 'sm'
            resolve:
                text: {text: ", что хотите удалить"}
        editModal.result.then((result)->
            if result
                deleteWork(education)
            return
        )
        return
    vm.getUserEducations = getUserEducations
    vm.newUserEducation = newUserEducation
    vm.confirmActionWork = confirmActionWork
    vm.removeWork = removeWork
    vm.editUserEducation = editUserEducation

    getUserEducations()
    return
.controller 'UsereducationEditController', ($rootScope,$base64, $scope, $state, RequestService, toastr, Session, flowFactory, $stateParams) ->
    'ngInject'
    vm = this
    vm.usereducation = {
        user_id: $scope.app.ua.id
    }
    if $stateParams.usereducation
        vm.usereducation = $stateParams.usereducation

    putDataEducation = ->
        RequestService.post 'education.save', vm.usereducation
        .then (result) ->
            vm.userwork = null
            toastr.success 'Изменения сохранены'
            $state.go 'app.usereducation.list'
            return

    cancelEducation = () ->
        $state.go 'app.usereducation.list'
        vm.userwork = null
        return

    vm.putDataEducation = putDataEducation
    vm.cancelEducation = cancelEducation

    return
