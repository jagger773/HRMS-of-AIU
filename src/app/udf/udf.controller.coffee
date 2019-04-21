angular.module 'stock'
.controller 'UdfController', ($scope, $state, $stateParams, RequestService, toastr, hotkeys, $uibModal, $uibModalStack) ->
    'ngInject'
    vm = this

    vm.offset = 0
    vm.limit = 10
    vm.udfsGridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs: [
            {name: 'name', displayName: 'Наименование'}
            {name: 'data.placeholder', displayName: 'Заполнитель'}
            {name: 'udf_purpose_value.data.name', displayName: 'Назначение'}
            {name: 'field_type_value.data.name', displayName: 'Элемент'}
            {name: 'data.icon', displayName: 'Иконка', visible: false}
            {name: 'data.min', displayName: 'Мин. значение', visible: false}
            {name: 'data.max', displayName: 'Макс. значение', visible: false}
            {name: 'data.step', displayName: 'Шаг', visible: false}
            {name: 'data.variables',displayName: 'Значаения',cellTemplate: '<div class="ui-grid-cell-contents" ><span ng-repeat="v in grid.getCellValue(row, col)">{{v.value}}{{!$last ? "," : ""}} </span></div>',visible: false}
            {name: 'company.name', displayName: 'Компания', visible: false}
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_udf = row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getUDFs()
                return

    getUDFs = ->
        filter =
            offset: vm.offset
            limit: vm.limit
            with_related: true
        RequestService.post 'udf.list', filter
        .then (result) ->
            delete  vm.selected_udf
            vm.udfsGridOptions.data = result.docs
            vm.udfsGridOptions.totalItems = result.count
            return
        return

    newUDF = ->
        editModal = $uibModal.open
            templateUrl: 'app/udf/edit.html'
            controller: 'UdfEditController'
            controllerAs: 'udf'
            size: 'lg'
            scope: $scope
            resolve:
                udf: undefined
                is_admin: $stateParams.is_admin

        editModal.result.then ->
            getUDFs()
        return

    editUDF = ->
        editModal = $uibModal.open
            templateUrl: 'app/udf/edit.html'
            controller: 'UdfEditController'
            controllerAs: 'udf'
            size: 'lg'
            scope: $scope
            resolve:
                udf: angular.copy vm.selected_udf
                is_admin: $stateParams.is_admin

        editModal.result.then ->
            getUDFs()
        return

    vm.getUDFs = getUDFs
    vm.newUDF = newUDF
    vm.editUDF = editUDF

    hotkeys.bindTo $scope
    .add {
        combo: 'n'
        description: 'Добавить поле'
        callback: newUDF
    }
    .add {
        combo: 'r'
        description: 'Обновить список полей'
        callback: getUDFs
    }
    getUDFs()
    return
.controller 'UdfEditController', ($scope, RequestService, toastr, $uibModalInstance, udf, is_admin) ->
    'ngInject'
    vm = this
    vm.udf = udf || {type: 'UDF'}

    putUDF = ->
        if vm.saving == true
            return
        if angular.isUndefined vm.udf.data.key
            toastr.warning 'Укажите параметр'
            vm.saving = false
            return
        if angular.isUndefined vm.udf.udf_purpose
            toastr.warning 'Выберите назначение'
            vm.saving = false
            return
        if angular.isUndefined vm.udf.data.field_type
            toastr.warning 'Выберите тип элемента'
            vm.saving = false
            return
        RequestService.post 'udf.save', vm.udf
        .then (result) ->
            vm.saving = false
            $uibModalInstance.close result
            return
        , ->
            vm.saving = false
        return

    withVariables = ->
        field_type = if vm.udf and vm.udf.data then vm.udf.data.field_type else undefined
        if vm.udf && (field_type == "select" || field_type == "multiSelect" || field_type == "checkbox" || field_type == "radio")
            return true
        return false

    hasIcon = ->
        field_type = if vm.udf and vm.udf.data then vm.udf.data.field_type else undefined
        if vm.udf && (field_type == "date" || field_type == "time" || field_type == "checkbox" || field_type == "radio" || !is_admin)
            return false
        return true

    addVariable = ->
        if vm.var_temp == undefined || vm.var_temp.key == undefined || vm.var_temp.value == undefined
            return false
        if vm.udf.data.variables == undefined
            vm.udf.data.variables = []
        delVariable(vm.var_temp)
        vm.udf.data.variables.push(angular.copy(vm.var_temp))
        vm.var_temp = {}
        return false

    delVariable = (variable) ->
        if vm.udf.data.variables == undefined
            vm.udf.data.variables = []
        for data_variable in vm.udf.data.variables
            if data_variable.key == variable.key
                index = vm.udf.data.variables.indexOf(data_variable)
                vm.udf.data.variables.splice(index, 1)
        return

    vm.putUDF = putUDF
    vm.withVariables = withVariables
    vm.hasIcon = hasIcon
    vm.addVariable = addVariable
    vm.delVariable = delVariable

    vm.cancel = ->
        $uibModalInstance.dismiss 'cancel'
        return
    return
