angular.module 'stock'
.controller 'UserrankController', ($rootScope, $scope, $state, RequestService) ->
    'ngInject'
    return
.controller 'UserrankListController', ($rootScope, $scope, $state, RequestService, $translate) ->
    'ngInject'
    vm = this
    vm.journals = []
    vm.offset = 0
    vm.limit = 20

    vm.userrankGridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs: [
            { displayName: 'Код', name: 'document_code', headerCellFilter: 'translate'}
            { displayName: 'Статус', name: 'actiontype.name_ru', headerCellFilter: 'translate'}
            { displayName: 'Дата утв.', name: 'action_date', headerCellFilter: 'translate', type: 'date', cellFilter: 'date:\'dd-MM-yyyy\'', width:150}
            { displayName: 'Документ', name: 'documenttype.name_ru', headerCellFilter: 'translate'}
            { displayName: 'document location', name: 'document_location', headerCellFilter: 'translate'}
            { displayName: 'Звание', name: 'academicrank.name_ru', headerCellFilter: 'translate'}
            { displayName: 'Комментарии', name: 'note', headerCellFilter: 'translate'}
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_userdegree = angular.copy row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getUserdegrees()
                return

    getUserranks = () ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        filter.user_id = $scope.app.ua.id
        filter.with_related = true
        filter.limit = vm.limit
        filter.offset = vm.offset
        RequestService.post('rank.listing', filter)
        .then (response) ->
            vm.userranks = response.docs
            vm.userrankGridOptions.data = vm.userranks
            vm.userrankGridOptions.totalItems = vm.userranks.length
            return
        return

    vm.getUserranks = getUserranks

    getUserranks()
    return
