angular.module 'stock'
.directive 'udfView', ($compile) ->
    return {
        restrict: 'E',
        scope: {
            udfTable: '@'
            udfData: '='
            udfPreView: '=?'
        },
        controller: ($scope, RequestService)->
            'ngInject'
            vm = this
            getUdfs = ->
                if angular.isDefined $scope.udfPreView
                    vm.udfs = [$scope.udfPreView]
                    return
                vm.loading = true
                filter =
                    filter:
                        udf_purpose: $scope.udfTable
                RequestService.post 'udf.list', filter
                .then (result)->
                    vm.loading = false
                    vm.udfs = result.docs
                    return
                , ->
                    vm.loading = false
                return
            $scope.$watch 'udfTable', (newVal)->
                if newVal != '' and angular.isDefined newVal
                    getUdfs()
                return
            vm.getUdfs = getUdfs
            return
        controllerAs: 'udf'
        templateUrl: 'app/udf/udf-field.html'
    }