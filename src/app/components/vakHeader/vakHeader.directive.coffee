angular.module 'stock'
.controller 'vakHeaderController', ($scope, $translate, RequestService, flowFactory, $base64, Session, toastr) ->
    'ngInject'
    vm = this
    changeLanguage = (langCode) ->
        $translate.use(langCode)
        return

    vm.changeLanguage = changeLanguage
    return



.directive 'vakHeader', ->
    restrict: 'E'
    replace: true
    scope:
        fileSrc: '='
        type: '@'
    controller: 'vakHeaderController'
    controllerAs: 'vak'
    templateUrl: 'app/components/vakHeader/vak-header.html'
