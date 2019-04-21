angular.module 'stock'
.controller 'AntiController', ($timeout, toastr, $translate, $rootScope,$http,$state) ->
    'ngInject'
    vm = this

    changeLanguage = (langCode) ->
        $translate.use(langCode)
        return

    vm.changeLanguage = changeLanguage
    return

