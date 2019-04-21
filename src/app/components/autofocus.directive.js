angular.module('stock')
    .directive('autofocus', function () {
        return {
            restrict: 'A',
            link: function ($scope, $element) {
                $element[0].focus();
            }
        }
    });
