angular.module 'stock'
.controller 'ArticlesController', ($rootScope, $scope, $state, RequestService) ->
    'ngInject'
    return
.controller 'ArticlesListController', ($rootScope, $scope, $state, RequestService, $translate) ->
    'ngInject'
    vm = this
    vm.articles = []
    vm.lang =  $translate.use().valueOf()

    vm.articleGridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs: [
            { displayName: 'NAME_RU_SPAN_LABEL', name: 'name_ru', headerCellFilter: 'translate'}
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_article = angular.copy row.entity
                vm.selected_article = vm.articles.find(
                    (elem) ->
                        if elem.id == vm.selected_article.id
                            return elem
                )
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getArticles()
                return

    getArticles = () ->
        RequestService.post('articles.listing')
        .then (response) ->
            vm.articles = response.docs
            vm.articleGridOptions.data = vm.articles
            vm.articleGridOptions.totalItems = vm.articles.length
            return
        return

    go = (path, param) ->
        $state.go path, param

    getCurrentLang = ->
        return $translate

    vm.getArticles = getArticles
    vm.getCurrentLang = getCurrentLang
    vm.go = go
    getArticles()

    return

.controller 'ArticlesFormController', ($rootScope, $scope, $state, $stateParams, RequestService, toastr) ->
    'ngInject'
    vm = this

    vm.article = $stateParams.article
    vm.isSaving = false

    networkError = (result) ->
        vm.isSaving = false
        console.log(result)
        toast if result then result else result:-1,message: 'Ошибка сети'

    pullJournals = () ->
        RequestService.post('journals.listing')
        .then (response) ->
            vm.journals = response.docs

    pullAuthors = () ->
        RequestService.post('user.listing')
            .then((response) ->
                vm.authors = response.users
                for user in vm.authors
                    user.fullname = user.first_name + " " + user.last_name
            networkError)

    pullTopics = () ->
        RequestService.post('dictionary.listing', {type: "Topics"})
            .then((response) ->
                vm.topics = response.docs
            networkError)

    toast = (result)->
        if result.result > 0
            toastr.warning result.message
        else if result.result < 0
            toastr.error result.message

    saveArticle = ->
        vm.isSaving = true
        RequestService.post('articles.save', vm.article)
        .then((response) ->
            vm.isSaving = false
            goBack()
        networkError)

    goBack = ->
        $state.go('app.articles.list')

    vm.saveArticle = saveArticle
    vm.goBack = goBack
    pullJournals()
    pullAuthors()
    pullTopics()
    return


.controller 'ArticlesViewController', ($rootScope, $scope, $state, $stateParams, RequestService, toastr) ->
    'ngInject'
    vm = this

    goBack = ->
        $state.go('app.articles.list')

    vm.article = $stateParams.article

    if Object.keys(vm.article).length == 0
        goBack()
        return
    networkError = (result) ->
        vm.isSaving = false
        console.log(result)
        toast if result then result else result:-1,message: 'Ошибка сети'


    pullJournals = () ->
        RequestService.post('journals.listing', {ids: [vm.article.journal_id]})
        .then (response) ->
            vm.journals = response.docs

    pullAuthors = () ->
        RequestService.post('user.listing', {ids: vm.article.authors})
            .then((response) ->
                vm.authors = response.users
                for user in vm.authors
                    user.fullname = user.first_name + " " + user.last_name
            networkError)


    pullTopics = () ->
        RequestService.post('dictionary.listing', {type: "Topics", ids: vm.article.topics})
            .then((response) ->
                vm.topics = response.docs
            networkError)

    pullAuthors()
    pullJournals()
    pullTopics()
    vm.goBack = goBack
    return
