angular.module 'stock'
.directive 'productSelect', ($parse) ->
    restrict: 'E'
    replace: true
    scope:
        productId: '='
        productUnitId: '=?'
        ngDisabled: '=?'
        modalOptions: '=?'
        onProductLoad: '&'
    controller: ($scope, RequestService, $uibModal) ->
        'ngInject'
        vm = this

        isEmpty = (value) ->
            angular.isUndefined(value) or value == null or value == ''

        vm.openSelectProduct = ->
            editModal = $uibModal.open
                templateUrl: 'app/components/productSelect/select.html'
                controller: 'ProductSelectController'
                controllerAs: 'product'
                size: 'lg'
                scope: $scope.$parent
                resolve:
                    modalOptions: $scope.modalOptions || {}
                    search: vm.selected

            editModal.result.then (result)->
                vm.selected = result
                return
            return

        vm.searchProduct = (search_name)->
            filter =
                limit: 10
                search: search_name
                filter: if $scope.modalOptions then $scope.modalOptions.filter
            RequestService.post 'theme.listing', filter
            .then (result)->
                result.docs

        $scope.$watch 'productId', (newVal, oldVal) ->
            if not isEmpty(newVal) and (newVal != oldVal or
                isEmpty(vm.selected) or vm.selected._id != newVal
            )
                RequestService.post 'theme.get', id:newVal
                .then (result) ->
                    vm.selected = result.doc
                    $scope.loadHandler $scope.$parent, $product: vm.selected
                    return
            else if isEmpty(newVal) and not isEmpty(vm.selected)
                vm.selected = null
            return
        $scope.$watch 'product.selected', ->
            if not isEmpty(vm.selected) and angular.isObject(vm.selected)
                if $scope.productId != vm.selected._id
                    $scope.productId = vm.selected._id
                $scope.productUnitId = if not isEmpty(vm.selected.data) then vm.selected.data.unit_id
            if isEmpty(vm.selected) and not isEmpty($scope.productId)
                delete $scope.productId
                delete $scope.productUnitId
            return

        return
    controllerAs: 'product'
    link: (scope, element, attr)->
        scope.loadHandler = $parse attr.onProductLoad
        return
    templateUrl: 'app/components/productSelect/product-select.html'
.directive 'productSelectName', ->
    restrict: 'E'
    replace: true
    scope:
        productId: '=?'
    controller: ($scope, RequestService) ->
        'ngInject'
        vm = this

        isEmpty = (value) ->
            angular.isUndefined(value) or value == null or value == ''

        $scope.$watch 'productId', (newVal, oldVal) ->
            if not isEmpty(newVal) and (newVal != oldVal or
                isEmpty(vm.selected) or vm.selected._id != newVal
            )
                RequestService.post 'product.get', id:newVal
                .then (result) ->
                    vm.selected = result.doc
                    return
            else if isEmpty(newVal) and not isEmpty(vm.selected)
                vm.selected = null
            return

        return
    controllerAs: 'product'
    templateUrl: 'app/components/productSelect/product-select-name.html'
