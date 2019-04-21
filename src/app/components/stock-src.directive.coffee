angular.module 'stock'
.directive 'stockSrc', ($rootScope, $compile) ->
    restrict: 'A'
    scope:
        stockSrc: '@'
    link: (scope, element, attr) ->
        if not attr.ngSrc
            attr.$set 'ng-src', $rootScope.api + scope.stockSrc
            $compile(element)(scope)
        return
