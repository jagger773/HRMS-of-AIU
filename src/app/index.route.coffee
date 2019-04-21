angular.module 'stock'
.config ($stateProvider, $urlRouterProvider) ->
    'ngInject'
    $stateProvider

    .state 'ais',
        url: '/ais'
        templateUrl: 'app/ais/ais.html'
        controller: 'AisController'
        controllerAs: 'ais'

    .state 'anti',
        url: '/anti-plagiarism'
        templateUrl: 'app/anti/anti.html'
        controller: 'AntiController'
        controllerAs: 'anti'

    .state 'journal',
        url: '/journal'
        templateUrl: 'app/ais/journal.html'
        controller: 'AisJournalController'
        controllerAs: 'journal'

    .state 'journal_page',
        url: '/journal-page'
        templateUrl: 'app/ais/journal-page.html'
        controller: 'AisJournalPageController'
        params: {id: null}
        controllerAs: 'page'

    .state 'app',
        abstract: true
        url: '/app'
        templateUrl: 'app/main/main.html'
        controller: 'MainController'
        controllerAs: 'app'

    .state 'login',
        url: '/login'
        params:
            params: null
        templateUrl: 'app/auth/login.html'
        controller: 'AuthController'
        controllerAs: 'auth'

    .state 'register',
        url: '/register'
        templateUrl: 'app/auth/register.html'
        controller: 'AuthController'
        controllerAs: 'auth'

    .state 'exist',
        url: '/user-exist'
        templateUrl: 'app/auth/exist.html'
        controller: 'AuthController'
        controllerAs: 'auth'

    .state 'confirm',
        url: '/confirm'
        templateUrl: 'app/auth/confirm.html'
        controller: 'AuthConfirmController'
        controllerAs: 'confirm'

    .state 'recover',
        url: '/recover'
        templateUrl: 'app/auth/recover.html'
        controller: 'AuthController'
        controllerAs: 'auth'

    .state 'sostav',
        url: '/sostav',
        templateUrl: 'app/about/sostav.html'
        controller: 'AboutController'
        controllerAs: 'about'

    .state 'structura',
        url: '/structura',
        templateUrl: 'app/about/structura.html'
        controller: 'AboutController'
        controllerAs: 'structura'

    .state 'prezidium',
        url: '/prezidium',
        templateUrl: 'app/about/prezidium.html'
        controller: 'AboutController'
        controllerAs: 'prezidium'

    .state 'expert',
        url: '/expert',
        templateUrl: 'app/about/expert.html'
        controller: 'AboutExpertController'
        controllerAs: 'expert'

    .state 'contact',
        url: '/contact',
        templateUrl: 'app/contact/contact.html'
        controller: 'ContactController'
        controllerAs: 'contact'

    .state 'news',
        url: '/news'
        templateUrl: 'app/news/news.html'
        controller: 'NewsController'
        controllerAs: 'news'

    .state 'page',
        url: '/page'
        templateUrl: 'app/page/page.html'
        controller: 'PageController'
        params: {news: null}
        controllerAs: 'page'


    .state 'advertpage',
        url: '/advertpage'
        templateUrl: 'app/advertpage/advertpage.html'
        controller: 'AdvertpageController'
        params: {adverts: null}
        controllerAs: 'advertpage'

    .state 'regulations',
        url: '/regulations'
        templateUrl: 'app/regulations/regulations.html'
        controller: 'RegulationsController'
        controllerAs: 'regulations'

    .state 'questions',
        url: '/questions'
        templateUrl: 'app/questions/questions.html'
        controller: 'QuestionsController'
        controllerAs: 'questions'

    .state 'activity',
        url: '/activity'
        templateUrl: 'app/activity/activity.html'
        controller: 'ActivityController'
        controllerAs: 'activity'

    .state 'view',
        url: '/view'
        templateUrl: 'app/activity/view.html'
        controller: 'ActivityViewController'
        params: {type: null}
        controllerAs: 'view'

    .state 'aspirant',
        url: '/aspirant'
        templateUrl: 'app/activity/aspirant.html'
        controller: 'ActivityAspirantController'
        controllerAs: 'aspirant'

    .state 'dissov',
        url: '/dissov'
        templateUrl: 'app/activity/dissov.html'
        controller: 'ActivityDissovController'
        params: {type: null}
        controllerAs: 'dissov'

    .state 'person',
        url:'/person',
        templateUrl:'app/activity/person.html',
        controller: 'ActivityPersonView',
        params:{person:null}
        controllerAs:'person'

    .state 'dissov_view',
        url: '/dissov-view'
        templateUrl: 'app/activity/dissovView.html'
        controller: 'ActivityDissovViewController'
        params: {disscouncil: {}}
        controllerAs: 'dissov_view'

    .state 'form',
        url: '/form'
        templateUrl: 'app/form/form.html'
        controller: 'FormController'
        controllerAs: 'form'

    i = [
        {'n': 'app.dashboard'}
        {'n': 'app.users'}
        {'n': 'app.profile', 'a': true}
        {'n': 'app.profile.view'}
        {'n': 'app.profile.preregistration'}
        {'n': 'app.profile.edit', p: {profile: {}}}
        {'n': 'app.menu'}
        {'n': 'app.menu.item', 'u': '.item/{id}'}
        {'n': 'app.role'}
        {'n': 'app.dictionary'}
        {'n': 'app.report'}
        {'n': 'app.report_template'}
        {'n': 'app.report_designer', u: '.report_designer/{id}'}
        {'n': 'app.banners', 'a':true, 'e':true}
        {'n': 'app.banners.list'}
        {'n': 'app.banners.form', p:{'banners':null}}
        {'n': 'app.regulations', 'a':true, 'e':true}
        {'n': 'app.regulations.list'}
        {'n': 'app.regulations.form', p:{'regulations':null}}
        {'n': 'app.news', 'a': true, 'e': true}
        {'n': 'app.news.list'}
        {'n': 'app.news.form', p:{'news':null}}
        {'n': 'app.adverts', 'a': true, 'e': true}
        {'n': 'app.adverts.list'}
        {'n': 'app.adverts.form', p:{'adverts':null}}
        {'n': 'app.questions', 'a': true, 'e': true}
        {'n': 'app.questions.list'}
        {'n': 'app.questions.form', p:{'questions':null}}
        {'n': 'app.rejecteddiss', 'a': true, 'e': true}
        {'n': 'app.rejecteddiss.list'}
        {'n': 'app.rejecteddiss.form', p:{'rejecteddiss':null}}
        {'n': 'app.persons', 'a': true, 'e': true}
        {'n': 'app.persons.list'}
        {'n': 'app.persons.view', p:{user: null}}
        {'n': 'app.persons.edit',p:{user: null}}
        {'n': 'app.journals', 'a': true, 'e': true}
        {'n': 'app.journals.list'}
        {'n': 'app.journals.form', p:{journal: {}}}
        {'n': 'app.journals.view', p:{journal: {}}}
        {'n': 'app.articles', 'a': true, 'e': true}
        {'n': 'app.articles.list'}
        {'n': 'app.articles.form', p:{article: {}}}
        {'n': 'app.articles.view', p:{article: {}}}
        {'n': 'app.theme', 'a': true, 'e': true}
        {'n': 'app.theme.list'}
        {'n': 'app.theme.create'}
        {'n': 'app.theme.edit', p:{theme: null}}
        {'n': 'app.works', 'a': true, 'e': true}
        {'n': 'app.works.list'}
        {'n': 'app.works.create'}
        {'n': 'app.works.view', p:{works: null}}
        {'n': 'app.disscouncil', 'a': true, 'e': true}
        {'n': 'app.disscouncil.list'}
        {'n': 'app.disscouncil.create'}
        {'n': 'app.disscouncil.view', p: {disscouncil: {}}}
        {'n': 'app.disscouncil.edit', p:{disscouncil: null}}
        {'n': 'app.disscouncil.application', p: {disscouncil: {}}}
        {'n': 'app.application', 'a': true, 'e': true}
        {'n': 'app.application.list'}
        {'n': 'app.application.dissov'}
        {'n': 'app.application.degree'}
        {'n': 'app.application.rank'}
        {'n': 'app.queue', 'a': true, 'e': true}
        {'n': 'app.queue.list'}
        {'n': 'app.queue.application'}
        {'n': 'app.queue.view', p: {document: null}}
        {'n': 'app.queue.registration', p: {document: null}}
        {'n': 'app.queue.protocol', p: {document: null}}
        {'n': 'app.userdegree', 'a': true, 'e': true}
        {'n': 'app.userdegree.list'}
        {'n': 'app.userrank', 'a': true, 'e': true}
        {'n': 'app.userrank.list'}
        {'n': 'app.userwork', 'a': true, 'e': true}
        {'n': 'app.userwork.list'}
        {'n': 'app.userwork.edit', p:{userwork: null}}
        {'n': 'app.usereducation', 'a': true, 'e': true}
        {'n': 'app.usereducation.list'}
        {'n': 'app.usereducation.edit', p:{usereducation: null}}

    ]

    for r in i
        url = r.n.substring(r.n.lastIndexOf('.') + 1)
        path = r.n.split('.')
        template = [path[0], path[1], (if path.length > 2 then path[2] else path[1]) + '.html'].join('/')
        path[1] = path[1].toUpperCase().charAt(0) + path[1].substring(1)
        if path.length > 2
            path[2] = path[2].toUpperCase().charAt(0) + path[2].substring(1)
        c = if path.length > 2 then path[1] + path[2] else path[1]
        args =
            url: '.' + url
            controller: c + 'Controller'
            controllerAs: url
            abstract: angular.isDefined r.a and r.a
        if angular.isDefined r.u
            args.url = r.u
        if angular.isDefined r.p
            args.params = r.p
        if angular.isDefined r.t
            args.template = r.t
        else if r.e
            args.template = '<ui-view></ui-view>'
        else
            args.templateUrl = template
        console.log 'Generated ' + r.n + ' as ' + angular.toJson args
        $stateProvider
        .state r.n, args

    $urlRouterProvider.otherwise '/ais'


