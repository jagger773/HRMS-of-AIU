
angular.module 'stock'
.controller 'DictionaryController', ($scope, RequestService, BObjectService, $state, $stateParams, toastr, $uibModal, $uibModalStack, spec_svan)->
    'ngInject'
    vm = this

    vm.offset = 0
    vm.limit = 50
    vm.gridOptions =
        noUnselect: true
        paginationPageSizes: [50, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs:[
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_dictionary = angular.copy row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getDictionaries()
                return

    listTables = ->
        RequestService.post 'dictionary.tables_list'
        .then (result)->
            vm.tables = result.tables
            if (angular.isUndefined vm.active_table) && vm.tables.length>0
                vm.active_table = vm.tables[0]
            return
        return

    getDictionaries = ->
        if angular.isUndefined vm.active_table
            listTables()
            return
        vm.filter =
            type: vm.active_table.table
            offset: vm.offset
            limit: vm.limit
            search: vm.search
            with_related: true
#        if angular.isDefined vm.active_table.name
#            filter.filter = {name: vm.active_table.name}

        RequestService.post 'dictionary.listing', vm.filter
        .then (result)->
            delete vm.selected_dictionary
            if result.table == vm.active_table.table
                vm.gridOptions.data = result.docs
                vm.gridOptions.totalItems = result.count
            return
        return

    newDictionary = ->
        editModal = $uibModal.open
            templateUrl: 'app/dictionary/modal.html'
            controller: 'DictionaryEditController'
            controllerAs: 'edit'
            size: 'lg'
            scope: $scope
            resolve:
                table: vm.active_table
                dictionary: undefined

        editModal.result.then ->
            getDictionaries()
        return

    editDictionary = ->
        editModal = $uibModal.open
            templateUrl: 'app/dictionary/modal.html'
            controller: 'DictionaryEditController'
            controllerAs: 'edit'
            size: 'lg'
            scope: $scope
            resolve:
                table: vm.active_table
                dictionary: angular.copy vm.selected_dictionary

        editModal.result.then ->
            getDictionaries()
        return

    removeDictionary = ->
        return if not vm.selected_dictionary
        vm.selected_dictionary.type = vm.active_table.table
        RequestService.post 'dictionary.remove', vm.selected_dictionary
        .then (result) ->
            BObjectService.clear()
            getDictionaries()
            return
        return

    addDictionary = ->
        vm.list =
            type: 'Branchesofscience'
            data: spec_svan
        RequestService.post 'countries.save_dict', vm.list
        .then (result) ->
            BObjectService.clear()
            getDictionaries()
            return
        return

    $scope.$watch 'dictionary.active_table', ->
        if angular.isDefined vm.active_table
            vm.gridOptions.columnDefs = ({
                displayName: column.displayName
                name: column.name
                visible: column.visible
                headerCellFilter: 'translate'
            } for column in vm.active_table.columns)

            vm.grid = '<paged-table options="dictionary.gridOptions" disable-search="true"></paged-table>'
            getDictionaries()
        return

    vm.getDictionaries = getDictionaries
    vm.newDictionary = newDictionary
    vm.editDictionary = editDictionary
    vm.removeDictionary = removeDictionary
    vm.addDictionary = addDictionary
    vm.grid = ''

    listTables()
    return
.controller 'DictionaryEditController', ($scope, RequestService, table, dictionary, $uibModalInstance, BObjectService) ->
    'ngInject'
    vm = this
    if angular.isUndefined table
        $uibModalInstance.dismiss 'cancel'
        return
    vm.template = 'app/dictionary/' + (table.table.toLowerCase()) + '/edit.html'
    if angular.isUndefined dictionary
        dictionary = {
            type: table.table
        }
    vm.table = table
    vm.dictionary = dictionary

    saveDictionary = ->
        if vm.preSave() == false
            return
        vm.dictionary.type = vm.table.table
        RequestService.post 'dictionary.save', vm.dictionary
        .then (result)->
            $uibModalInstance.close result
            BObjectService.clear()
            return
        return

    vm.preSave = ->
        return
    vm.cancel = ->
        $uibModalInstance.dismiss 'cancel'
        return
    vm.saveDictionary = saveDictionary
    return
