angular.module 'stock'
.directive 'themeSelect', ($parse) ->
    restrict: 'E'
    replace: true
    scope:
        themeId: '='
        themeUnitId: '=?'
        ngDisabled: '=?'
        modalOptions: '=?'
        onThemeLoad: '&'
    controller: ($scope, RequestService, $uibModal) ->
        'ngInject'
        vm = this

        isEmpty = (value) ->
            angular.isUndefined(value) or value == null or value == ''

        vm.openSelectTheme = ->
            editModal = $uibModal.open
                templateUrl: 'app/components/themeSelect/select.html'
                controller: 'ThemeSelectController'
                controllerAs: 'theme'
                size: 'lg'
                scope: $scope.$parent
                resolve:
                    modalOptions: $scope.modalOptions || {}
                    search: vm.selected

            editModal.result.then (result)->
                vm.selected = result
                return
            return

        vm.searchTheme = (search_name)->
            filter =
                limit: 10
                search: search_name
                filter: if $scope.modalOptions then $scope.modalOptions.filter
            RequestService.post 'theme.listing', filter
            .then (result)->
                result.docs

        $scope.$watch 'themeId', (newVal, oldVal) ->
            if not isEmpty(newVal) and (newVal != oldVal or
                isEmpty(vm.selected) or vm.selected._id != newVal
            )
                RequestService.post 'theme.get', id:newVal
                .then (result) ->
                    vm.selected = result.doc
                    $scope.loadHandler $scope.$parent, $theme: vm.selected
                    return
            else if isEmpty(newVal) and not isEmpty(vm.selected)
                vm.selected = null
            return
        $scope.$watch 'theme.selected', ->
            if not isEmpty(vm.selected) and angular.isObject(vm.selected)
                if $scope.themeId != vm.selected._id
                    $scope.themeId = vm.selected._id
                $scope.themeUnitId = if not isEmpty(vm.selected.data) then vm.selected.data.unit_id
            if isEmpty(vm.selected) and not isEmpty($scope.themeId)
                delete $scope.themeId
                delete $scope.themeUnitId
            return

        return
    controllerAs: 'theme'
    link: (scope, element, attr)->
        scope.loadHandler = $parse attr.onThemeLoad
        return
    templateUrl: 'app/components/themeSelect/theme-select.html'
.directive 'themeSelectName', ->
    restrict: 'E'
    replace: true
    scope:
        themeId: '=?'
    controller: ($scope, RequestService) ->
        'ngInject'
        vm = this

        isEmpty = (value) ->
            angular.isUndefined(value) or value == null or value == ''

        $scope.$watch 'themeId', (newVal, oldVal) ->
            if not isEmpty(newVal) and (newVal != oldVal or
                isEmpty(vm.selected) or vm.selected._id != newVal
            )
                RequestService.post 'theme.get', id:newVal
                .then (result) ->
                    vm.selected = result.doc
                    return
            else if isEmpty(newVal) and not isEmpty(vm.selected)
                vm.selected = null
            return

        return
    controllerAs: 'theme'
    templateUrl: 'app/components/themeSelect/theme-select-name.html'
