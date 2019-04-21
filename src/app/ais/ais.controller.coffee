angular.module 'stock'
.controller 'AisController', (toastr, $translate, $rootScope, $http, $state, RequestService, $scope) ->
    'ngInject'
    vm = this
    vm.news = {}
    vm.api = $rootScope.api

    getNews = () ->
        RequestService.post('news/mainlisting').then (result) ->
            vm.news = result.docs
        return

    getBanners = () ->
        RequestService.post('banners/listing').then (result) ->
            vm.banners = result.docs
        return

    newsGo = () ->
        $state.go 'news'

    goToNewsPage = (news) ->
        $state.go 'page', {news:news}
        return

    changeLanguage = (langCode) ->
        $translate.use(langCode)
        return

    vm.labels = ['Физико-мат техн', 'Биол мед', 'Общ и гум']
    vm.series = ['Науки']
    vm.data = [[16,20,16,0]]
    vm.labelsd = [
      '2013'
      '2014'
      '2015'
      '2016'
      '2017'
    ]
    vm.seriesd = [
      'Series A'
      'Series B'
    ]
    vm.datad = [
      [
        55
        60
        60
        51
        52
        40
        80
      ]
    ]

    onClick = (points, evt) ->
      return

    vm.datasetOverrided = [
      { yAxisID: 'y-axis-1' }
    ]
    vm.optionsd = scales: yAxes: [
      {
        id: 'y-axis-1'
        type: 'linear'
        display: true
        position: 'left'
      }
    ]
    vm.labelssc = [
      'Кандидаты наук'
      'Доктора наук'
    ]
    vm.seriessc = [
      'Научные кадры'
    ]
    vm.datasc = [
      [
        225
        665
      ]
    ]

    vm.getBanners = getBanners
    vm.changeLanguage = changeLanguage
    vm.getNews = getNews
    vm.changeLanguage = changeLanguage
    vm.newsGo = newsGo
    vm.goToNewsPage = goToNewsPage
    vm.onClick = onClick

    getBanners()
    getNews()
    return
.controller 'AisJournalController', ($http,$rootScope, $scope, $state, $translate) ->
    'ngInject'
    vm = this
    vm.ser_url = $rootScope.api

    getJournals = ()->
        $http.post($rootScope.api + 'get_journals')
        .then (data) ->
            vm.journals = data.data.journals
        return

    goToPage = (id) ->
        $state.go  'journal_page', {id: id}
        return

    changeLanguage = (langCode) ->
        $translate.use(langCode)
        return

    vm.changeLanguage = changeLanguage
    vm.getJournals = getJournals
    vm.goToPage = goToPage
    getJournals()
    return

.controller 'AisJournalPageController', ($http,$rootScope, $scope, $stateParams) ->
    'ngInject'
    vm = this
    vm.articles_id = $stateParams.id

    getArticles = ()->
        $http.post($rootScope.api + 'get_articles/' + vm.articles_id)
        .then (result) ->
            vm.articles = result.data
        return

    changeLanguage = (langCode) ->
        $translate.use(langCode)
        return


    vm.changeLanguage = changeLanguage
    vm.getArticles = getArticles
    getArticles()
    return
