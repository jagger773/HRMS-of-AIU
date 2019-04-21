angular.module 'stock'
.controller 'FormController', ($timeout, toastr, $translate, $rootScope,$http,$state) ->
    'ngInject'
    vm = this
    vm.questionItem = {}

    goBack = () ->
        $state.go 'questions'
        return

    postQuestinos = () ->
        $http.post($rootScope.api + 'questions/put_question', vm.questionItem).then (response) ->
            if response.data.response == 'OK'
                console.log(response)
                toastr.success('Ваш вопрос был успешно отправлен')
                goBack()
            else
                toastr.warning('Ошибка')
        return

    changeLanguage = (langCode) ->
        $translate.use(langCode)
        return

    vm.goBack = goBack
    vm.postQuestions = postQuestinos
    vm.changeLanguage = changeLanguage
    return
