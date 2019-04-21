angular.module 'stock'
.directive 'employeeSelect', ->
    restrict: 'E'
    replace: true
    scope:
        employeeId: '='
        asText: '='
        ngDisabled: '=?'
    controller: ($scope, $rootScope, RequestService, $uibModal, $uibModalStack) ->
        'ngInject'
        vm = this
        vm.api = $rootScope.api
        vm.openSelectEmployee = ->
            editModal = $uibModal.open
                templateUrl: 'app/components/employeeSelect/select.html'
                controller: 'EmployeeSelectController'
                controllerAs: 'employee'
                size: 'lg'
                scope: $scope.$parent
                resolve:
                    modalOptions: {}

            editModal.result.then (result)->
                vm.selected = result
                return
            return

        vm.searchEmployee = (search_name)->
            RequestService.post 'company.employees', {
                username: search_name
                limit: 10
                with_related: ['user']
            }
            .then (result)->
                result.docs

        $scope.$watch 'employeeId', ->
            if (angular.isDefined $scope.employeeId) && vm.watch_prevent != true
                RequestService.post 'company.employees', {
                    with_related: true
                    filter:
                        user_id: $scope.employeeId
                }
                .then (result)->
                    if result.docs.length == 1
                        vm.watch_prevent = true
                        vm.selected = result.docs[0]
                    return
            vm.watch_prevent = false
            return
        $scope.$watch 'employee.selected', ->
            if (angular.isDefined vm.selected) && vm.watch_prevent != true
                vm.watch_prevent = true
                $scope.employeeId = vm.selected.user_id
            vm.watch_prevent = false
            return

        return
    controllerAs: 'employee'
    link: (scope, element, attr)->
        return
    templateUrl: 'app/components/employeeSelect/employee-select.html'
.directive 'employeeSelectName', ->
    restrict: 'E'
    replace: true
    scope:
        employeeId: '=?'
    controller: ($scope, RequestService) ->
        'ngInject'
        vm = this

        isEmpty = (value) ->
            angular.isUndefined(value) or value == null or value == ''

        $scope.$watch 'employeeId', (newVal, oldVal) ->
            if not isEmpty(newVal) and (newVal != oldVal or
                isEmpty(vm.selected) or vm.selected._id != newVal
            )
                RequestService.post 'company.employees', {with_related: true, filter: user_id:newVal}
                .then (result) ->
                    vm.selected = if result.docs and result.docs.length > 0 then result.docs[0]
                    return
            else if isEmpty(newVal) and not isEmpty(vm.selected)
                vm.selected = null
            return

        return
    controllerAs: 'employee'
    templateUrl: 'app/components/employeeSelect/employee-select-name.html'
