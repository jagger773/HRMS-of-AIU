angular.module 'stock'
.controller 'AdvertpageController', ($timeout, toastr, $translate, $rootScope,$http,$state,$stateParams) ->
    'ngInject'
    vm = this
    vm.adverts = $stateParams.adverts
    vm.api = $rootScope.api

    goBack = () ->
        if vm.adverts == null
            $state.go 'adverts'
            return

    changeLanguage = (langCode) ->
        $translate.use(langCode)
        return


    vm.changeLanguage = changeLanguage
    vm.goBack = goBack
    goBack()
    return

