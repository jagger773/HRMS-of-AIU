angular.module 'stock'
.controller 'vakFooterController', ($scope, $rootScope, RequestService, flowFactory, $base64, Session, toastr) ->
    'ngInject'
    vm = this

    return



.directive 'vakFooter', ->
    restrict: 'E'
    replace: true
    scope:
        fileSrc: '='
        type: '@'
    controller: 'vakFooterController'
    controllerAs: 'vak-footer'
    templateUrl: 'app/components/vakFooter/vak-footer.html'
