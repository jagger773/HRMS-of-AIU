angular.module 'stock'
.controller 'NewsController', (RequestService, $timeout, toastr, $translate, $rootScope,$http,$state) ->
    'ngInject'
    vm = this
    vm.offset = 0
    vm.limit = 20
    vm.news = {}
    vm.adverts = {}
    vm.listOfNames = []
    vm.newsId = ''

    getNews = (section_id) ->
        filter = {filter:{}}
        filter.offset = vm.offset
        filter.limit = vm.limit
        filter.with_related = true
        filter.sectionsofpublication_id = section_id
        RequestService.post('news/listing', filter)
        .then((response) ->
            vm.news = response.docs
            return
        (response) ->
            return)
        return

    getSectionsofpublications = ()->
        $http.get($rootScope.api + 'sectionofpublication/listing').then (result) ->
            vm.sectionsofpublications = result.data.docs
            vm.newsId = vm.sectionsofpublications[5]._id
            getNews(vm.newsId)
        return

    filterName = (inputName) ->
        vm.listOfNames = []
        if inputName.length != 0
            i = 0
            while i < vm.news.news.length
                if vm.news.news[i].name_ru.substring(0,inputName.length).toLowerCase()==inputName.toLowerCase()
                    vm.listOfNames.push(vm.news.news[i].name_ru)
                    vm.news.data = vm.news.news[i]
                else
                    error = "Ничего не найдено"
                    vm.listOfNames.push(error)
                    vm.news = {}
                i++
                return
        return

    changeLanguage = (langCode) ->
        $translate.use(langCode)
        return

    goToAdvertsPage = (adverts) ->
        $state.go 'advertpage', {adverts:adverts}
        return

    goToNewsPage = (news) ->
        $state.go 'page', {news:news}
        return


    vm.filterName = filterName
    vm.getNews = getNews
    vm.getSectionsofpublications = getSectionsofpublications
    vm.goToAdvertsPage = goToAdvertsPage
    vm.goToNewsPage = goToNewsPage
    vm.changeLanguage = changeLanguage
    getSectionsofpublications()

    return
.controller 'NewsListController', ($rootScope, $scope, $state, RequestService, $http, $translate) ->
    'ngInject'
    vm = this
    vm.offset = 0
    vm.limit = 20
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
                displayName: 'NAME_RU_SPAN_LABEL', name: 'name_ru', headerCellFilter: 'translate'
            }
            {
                displayName: 'NAME_KG_SPAN_LABEL', name: 'name_kg', headerCellFilter: 'translate'
            }
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_news = angular.copy row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getNews()
                return

    getNews = () ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        for k,v of vm.filter
            if k == "first_name"
                filter.filter.first_name = v
            if k == "last_name"
                filter.filter.last_name = v
            if k == "middle_name"
                filter.filter.middle_name = v
        filter.offset = vm.offset
        filter.limit = vm.limit
        filter.with_related = true
        RequestService.post('news/listing', filter)
        .then((response) ->
            vm.gridOptions.data = response.docs
            return
        (response) ->
            return)
        return

    openCreateForm = ->
        $state.go('app.news.form')
        return

    openEditForm = ->
        $state.go 'app.news.form', {news:vm.selected_news}

    removeNews = ->
        return if not vm.selected_news
        vm.selected_news.crud = 'News'
        RequestService.post 'news/delete', vm.selected_news
        .then (result) ->
            getNews()
            return
        return
    vm.removeNews = removeNews
    vm.getNews = getNews
    vm.openCreateForm = openCreateForm
    vm.openEditForm = openEditForm
    getNews()

    return
.controller 'NewsFormController', ($rootScope, $scope, $state, $stateParams, RequestService, $http, hotkeys, db, Session, AppStorage, toastr, $base64, $uibModal) ->
    'ngInject'
    vm = this
    vm.newsItem = $stateParams.news
    if angular.isUndefined vm.newsItem or vm.newsItem == null
        goBack()

    vm.files = {}
    vm.uploader =
        controllerFn:  ($flow, $file, $message) ->
            $file.msg = $message
            toastr.info('Файл загружен')

    upload = () ->
        vm.uploader.flow.opts.testChunks=false
        vm.uploader.flow.opts.singleFile = false
        vm.uploader.flow.opts.target = $rootScope.api + 'uploadfiles/default_save'
        vm.uploader.flow.opts.withCredentials = true
        vm.uploader.flow.opts.headers = {Authorization: 'Basic ' + $base64.encode('web' + ':' + Session.getToken())}
        vm.uploader.flow.opts.message = 'upload file'
        vm.uploader.flow.upload()
        return

    saveNews = ->
        vm.newsItem.files = (JSON.parse(url.msg).file for url in vm.uploader.flow.files)
        RequestService.post('news/put', vm.newsItem)
        .then((response) ->
            goBack()
            return
        (response) ->
            return)
        return

    goBack = ->
        $state.go('app.news.list')
        return

    vm.saveNews = saveNews
    vm.goBack = goBack
    vm.upload = upload

    return
