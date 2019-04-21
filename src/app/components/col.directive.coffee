angular.module 'stock'
.directive 'colResponsive', ->
    return {
        restrict: 'E'
        transclude: true
        replace: true
        template: '<div class="col col-xs-12 col-sm-6 col-md-6 col-lg-4" ng-transclude></div>'
    }
