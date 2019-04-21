angular.module 'stock'
.controller 'PageController', ($timeout, toastr, $translate, $rootScope,$http,$state,$stateParams) ->
    'ngInject'
    vm = this
    vm.news = $stateParams.news
    vm.api = $rootScope.api

    goBack = () ->
        if vm.news == null
            $state.go 'news'
            return

    changeLanguage = (langCode) ->
        $translate.use(langCode)
        return


    vm.changeLanguage = changeLanguage
    goBack()
    return

