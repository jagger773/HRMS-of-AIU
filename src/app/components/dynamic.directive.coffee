angular.module 'stock'
.directive 'dynamic', ($compile)->
    link = (scope, ele, attrs) ->
        scope.$watch attrs.dynamic, (html) ->
            ele.html(html)
            $compile(ele.contents())(scope)
        return
    {
        restrict: 'A',
        replace: true,
        link: link
    }
