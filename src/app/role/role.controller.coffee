angular.module 'stock'
.controller 'RoleController', ($scope, db, $state, RequestService, toastr, hotkeys, $uibModal, $uibModalStack) ->
    'ngInject'
    vm = this

    vm.rolesGridOptions =
        noUnselect: true
        columnDefs: [
            {name: 'name', displayName: 'Наименование'}
            {name: 'data.approval_name', displayName: 'Наим. для одобрения'}
            {name: 'data.read', displayName: 'Чтение'}
            {name: 'data.write', displayName: 'Редактирование'}
            {name: 'data.delete', displayName: 'Удаление'}
            {name: 'company.name', displayName: 'Компания', visible: false}
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_role = row.entity
                return

    getRoles = ->
        filter =
            with_related: true
        RequestService.post 'role.list', filter
        .then (result) ->
            delete vm.selected_role
            vm.roles = result.docs
            vm.rolesGridOptions.data = vm.roles
            return
        return

    editRole = ->
        editModal = $uibModal.open
            templateUrl: 'app/role/edit.html'
            controller: 'RoleEditController'
            controllerAs: 'role'
            size: 'lg'
            scope: $scope
            resolve:
                role: angular.copy vm.selected_role

        editModal.result.then ->
            getRoles()
        return false

    newRole = ->
        editModal = $uibModal.open
            templateUrl: 'app/role/edit.html'
            controller: 'RoleEditController'
            controllerAs: 'role'
            size: 'lg'
            scope: $scope
            resolve:
                role: undefined

        editModal.result.then ->
            getRoles()
        return

    hotkeys.bindTo $scope
    .add {
        combo: 'n'
        description: 'Добавить роль'
        callback: newRole
    }
    .add {
        combo: 'r'
        description: 'Обновить список ролей'
        callback: getRoles
    }

    vm.getRoles = getRoles
    vm.editRole = editRole
    vm.newRole = newRole

    getRoles()
    return
angular.module 'stock'
.controller 'RoleEditController', ($scope, RequestService, AppStorage, toastr, role, $uibModalInstance) ->
    'ngInject'
    vm = this
    vm.role = role || {type: 'Roles', data: {read: true}}
    if !vm.role.menus_id
        vm.role.menus_id = []

    vm.menus = AppStorage.getObject('menus') || []
    (menu.selected = true) for menu in vm.menus when -1 < vm.role.menus_id.indexOf menu._id

    saveRole = ->
        vm.role.type = 'Roles'
        RequestService.post 'role.save', vm.role
        .then (result) ->
            $uibModalInstance.close result
            return
        return false

    setMenusId = ->
        vm.role.menus_id = []
        (vm.role.menus_id.push menu._id) for menu in vm.menus when menu.selected

    menuCheckedChange = (menu) ->
        if menu && menu.parent_id == null && !menu.selected
            (menu_child.selected = false for menu_child in vm.menus when menu_child.parent_id == menu._id)
        if menu && menu.parent_id != null && menu.selected
            (menu_parent.selected = true for menu_parent in vm.menus when menu_parent._id == menu.parent_id)
        setMenusId()
        return

    vm.saveRole = saveRole
    vm.menuCheckedChange = menuCheckedChange

    vm.cancel = ->
        $uibModalInstance.dismiss 'cancel'
        return
    return
