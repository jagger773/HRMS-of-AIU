angular.module 'stock'
.controller 'QuestionsController', ($timeout, toastr, $translate, $rootScope,$http,$state) ->
    'ngInject'
    vm = this
    vm.questions = {}

    getQuestions = () ->
        $http.get($rootScope.api + 'questions/listing').then (result) ->
            vm.questions = result.data
        return

    changeLanguage = (langCode) ->
        $translate.use(langCode)
        return

    vm.getQuestins = getQuestions
    vm.changeLanguage = changeLanguage
    getQuestions()
    return

.controller 'QuestionsListController', ($rootScope, $scope, $state, RequestService, $http, $translate) ->
    'ngInject'
    vm = this
    vm.searchValues = {}
    vm.searchValuesLang = {}
    vm.dateOptions =
        startingDay: 1
        opened1: false
        opened2: false

    vm.gridOptions =
        noUnselect: true
        paginationPageSizes: [100, 200, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs:[
            {
                displayName: 'PERSON_NAME_LABEL', name: 'name', headerCellFilter: 'translate'
            }
            {
                displayName: 'CITY_NAME_LABEL', name: 'city', headerCellFilter: 'translate'
            }
            {
                displayName: 'ACTIVE_LABEL', name: 'is_active', headerCellFilter: 'translate'
            }
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_questions = angular.copy row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getQuestions()
                return

    getQuestions = () ->
        vm.searchValues.lang =  $translate.use().valueOf()
        filters = vm.searchValues
        RequestService.post('questions/listing', filters)
        .then((response) ->
            vm.gridOptions.data = response.list
            return
        (response) ->
            return)
        return

    openCreateForm = ->
        $state.go('app.questions.form')
        return

    openEditForm = ->
        $state.go 'app.questions.form', {questions:vm.selected_questions}


    removeQuestions = ->
        return if not vm.selected_questions
        vm.selected_questions.crud = 'News'
        RequestService.post 'questions/remove', vm.selected_questions
        .then (result) ->
            getQuestions()
            return
        return
    vm.removeQuestions = removeQuestions
    vm.getQuestions = getQuestions
    vm.openCreateForm = openCreateForm
    vm.openEditForm = openEditForm
    getQuestions()

    return
.controller 'QuestionsFormController', ($rootScope, $scope, $state, $stateParams, RequestService, $http) ->
    'ngInject'
    vm = this
    vm.questionsItem = $stateParams.questions

    saveQuestions = ->
        RequestService.post('questions/put_answer', vm.questionsItem)
        .then((response) ->
            goBack()
            return
        (response) ->
            console.log(response)
            return)
        return

    goBack = ->
        $state.go('app.questions.list')
        return

    vm.saveQuestions = saveQuestions
    vm.goBack = goBack

    return
