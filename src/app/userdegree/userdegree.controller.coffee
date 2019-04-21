angular.module 'stock'
.controller 'UserdegreeController', ($rootScope, $scope, $state, RequestService) ->
    'ngInject'
    return
.controller 'UserdegreeListController', ($rootScope, $scope, $state, RequestService, $translate) ->
    'ngInject'
    vm = this
    vm.journals = []
    vm.offset = 0
    vm.limit = 20

    vm.userdegreeGridOptions =
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
            { displayName: 'Степень', name: 'academicdegree.name_ru', headerCellFilter: 'translate'}
            { displayName: 'Специальность', name: 'specialty.name_ru', headerCellFilter: 'translate', cellTemplate: '<li class="animate-repeat" ng-repeat="speciality in degreespeciality">{{speciality.specialty.code}}-{{speciality.specialty.name_ru}}</li>',}
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

    getUserdegrees = () ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        filter.user_id = $scope.app.ua.id
        filter.with_related = true
        filter.limit = vm.limit
        filter.offset = vm.offset
        RequestService.post('degree.listing', filter)
        .then (response) ->
            vm.userdegrees = response.docs
            vm.userdegreeGridOptions.data = vm.userdegrees
            vm.userdegreeGridOptions.totalItems = vm.userdegrees.length
            return
        return

    vm.getUserdegrees = getUserdegrees

    getUserdegrees()
    return
