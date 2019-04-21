angular.module 'stock'
.controller 'MainController', ($scope, db, AppStorage, $rootScope, RequestService, $state, Session, EVENTS, $window, toastr, $translate,$location) ->
    'ngInject'
    vm = this

    $scope.$on EVENTS.notAuthenticated, ->
        Session.destroy()
        delete vm.ua
        $state.go('ais', if $state.current.name !='ais' then {r: $state.current.name, params: $state.params})
        AppStorage.clear()
    $scope.$on EVENTS.businessError, (e, message) ->
        toastr.warning message
    $scope.$on EVENTS.applicationError, (e, message) ->
        toastr.error message
    $scope.$on EVENTS.connectionError, ->
        toastr.error 'Проверьте соединение с сервером'
    $scope.$on EVENTS.successMessage, (e, message) ->
        toastr.success message

    vm.changeLanguage = (langCode) ->
        $translate.use(langCode)
        return

    $rootScope.company = {name: "ICT LAB", id: 1}
    $rootScope.branch = {name: "Main Office", id: 5}
    $rootScope.user = {name: "User", id: 1}
    add = ->
        db.instance.post({
            type: 'test'
            data: {date: new Date().toJSON()}
        })
    vm.api = $rootScope.api
    vm.ua = Session.getUser()
    vm.uc = Session.getUserCompany()


    logOut = ->
        $scope.$emit(EVENTS.notAuthenticated)

    if !Session.getToken() or !vm.ua
        logOut()
        return

    vm.navigation = AppStorage.getObject('navigation') || []

    if vm.ua.role >= 10
        vm.admin_menu = [{name: 'Настройки', data: {icon: 'fa fa-cogs', position: 1}, children: [
                {name: 'Меню', data: {
                    route: 'app.menu'
                    position: 1
                }}
                {name: 'Роли', data: {
                    route: 'app.role'
                    position: 2
                }}
                {name: 'Пользователи', data: {
                    route: 'app.users'
                    position: 3
                }}
                {name: 'Справочники', data: {
                    route: 'app.dictionary'
                    position: 3
                }}
                {name: 'Шаблоны отчетов', data: {
                    route: 'app.report_template'
                    position: 5
                }}
            ]}]

    getMenus = ->
        filter = {
            with_related: true
        }
        RequestService.post 'menu.listing', filter
        .then (result) ->
            parents = []
            children = []
            for menu in result.docs
                if menu.parent_id == null || angular.isUndefined menu.parent_id
                    parents.push(menu)
                else
                    children.push(menu)
            for menu in parents
                menu.children = []
                for child in children
                    if menu._id == child.parent_id
                        menu.children.push(child)
            vm.navigation = parents
            AppStorage.setObject('navigation', vm.navigation)
            AppStorage.setObject('menus', result.docs)
            $scope.$broadcast('menus-updated')

#    getNotifications = ->
#        RequestService.post 'notification.listing', {}
#        .then (result)->
#            vm.notifications = result.notifications
#            vm.notifications_count = result.count
#
#    readNotification = (notification)->
#        RequestService.post 'notification.read', notification
#        .then (result)->
#            $state.go('app.approval.view', {id:result.notification.data.document_id, type: result.notification.data.document_type})

    # Для группирования по родителю в ui-select
    parentGroup = (item) ->
        if !item.parent
            return ''
        return item.parent.name

    $scope.$on 'refresh-menus', ->
        getMenus()
        return

    $scope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams, options)->
        return

#    $scope.$on '$stateChangeSuccess', (event, toState, toParams, fromState, fromParams)->
#        getNotifications()
#        return
#
#    setInterval getNotifications, 60*1000

    goBack = ->
        if $window.history.length == 1
            $state.go("app.docs.list")
            return
        $window.history.back()
        return

    destroy = ->
        db.destroy()
        toastr.success 'БД очишено'
        return

    initDB = ->
        db.initDB()
        toastr.success 'БД инициализировано'
        return

    # config
    vm.app =
        name: 'VAK'
        merchant: if $location.host().indexOf('.') < 0 then 'АИС ВАК' else $location.host().split('.')[0]
        version: '2.0.0'
        color:
            primary: '#7266ba'
            info: '#23b7e5'
            success: '#27c24c'
            warning: '#fad733'
            danger: '#f05050'
            light: '#e8eff0'
            dark: '#3a3f51'
            black: '#1c2b36'
        settings:
            themeID: 1
            navbarHeaderColor: 'bg-black'
            navbarCollapseColor: 'bg-white-only'
            asideColor: 'bg-black'
            headerFixed: true
            asideFixed: true
            asideFolded: true
            asideDock: false
            container: false

    vm.logOut = logOut
    vm.destroy = destroy
    vm.initDB = initDB
    vm.getMenus = getMenus
#    vm.getNotifications = getNotifications
#    vm.readNotification = readNotification

    vm.parentGroup = parentGroup

    $scope.goBack = goBack

    getMenus()
#    getNotifications()
    return
