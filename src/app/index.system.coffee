angular.module 'stock'
.service 'BObjectService', ($rootScope, RequestService, $cacheFactory, $q)->
    bObject = {}
    dictionaryCache = $cacheFactory('dictionaries')

    bObject.list = (type, filter, nocache)->
        if angular.isUndefined filter
            filter = {}
        filter.type = type
        defer = $q.defer()
        data = null
        if angular.isUndefined(nocache) || nocache == false
            data = dictionaryCache.get(type + JSON.stringify(filter))
        if data
            defer.resolve(data)
        else
            RequestService.post 'dictionary.listing', filter
            .then (data)->
                dictionaryCache.put(type + JSON.stringify(filter), data)
                defer.resolve data
            , (data)->
                defer.reject data
        return defer.promise
    bObject.clear = ->
        dictionaryCache.removeAll()
    return bObject

.service 'RequestService', ($http, $rootScope, $q) ->
    return {
        post: (methodName, data, silent, timeOutSec) ->
            timeOutSec = timeOutSec || 60
            timeout = $q.defer()
            result = $q.defer()
            timedOut = false
            timedOutFunc = ->
                timedOut = true
                timeout.resolve()
                return
            setTimeout timedOutFunc, 100000 * timeOutSec
            if silent
                silent
            data = data || {}
            $rootScope.httPromise = $http({
                method: 'post',
                url: $rootScope.api + methodName,
                data: data,
                cache: false,
                timeout: timeout.promise
            }).success((data, status, headers, config) ->
                if !silent
                    !silent
                if data.result == 0
                    result.resolve(data)
                else
                    result.reject(data)
            ).error((data, status, headers, config) ->
                if timedOut
                    data = {
                        error: 'timeout',
                        message: 'Request took longer than ' + timeOutSec + ' seconds.'
                    }
                if !silent
                    !silent
                result.reject(data)
            )
            return result.promise
    }

.service 'browser', ($window) ->
    userAgent = $window.navigator.userAgent
    return -> userAgent

.service 'Session', ($localStorage) ->
    return {
        create: (token, user, uc) ->
            $localStorage.token = token
            $localStorage.user = user
            $localStorage.uc = uc
            return
        ,
        setUser: (user) ->
            $localStorage.user = user
            return
        ,
        setUserCompany: (uc) ->
            $localStorage.uc = uc
            return
        ,
        destroy: ->
            delete $localStorage.token
            delete $localStorage.user
            delete $localStorage.uc
            return
        ,
        getToken: ->
            return $localStorage.token
        ,
        getUser: ->
            return $localStorage.user
        ,
        getUserCompany: ->
            return $localStorage.uc
    }

.service 'AppStorage', ($window) ->
    return {
        set: (key, value) ->
            $window.localStorage[key] = value
            return
        ,
        get: (key) ->
            return $window.localStorage[key] || null
        ,
        setObject: (key, value) ->
            $window.localStorage[key] = JSON.stringify(value)
            return
        ,
        getObject: (key) ->
            return JSON.parse($window.localStorage[key] || null)
        ,
        remove: (key) ->
            try
                $window.localStorage.removeItem(key)
            catch err
            return
        ,
        clear: () ->
            try
                $window.localStorage.clear()
            catch err
            return
    }

.service 'confirmModal', ($uibModal)->
    return {
        open: (title, description, options)->
            return $uibModal.open
                templateUrl: 'app/templates/confirm-modal.html'
                resolve:
                    title: -> title
                    description: -> description
                    options: -> options
                controller: ($scope, title, description, options, $uibModalInstance)->
                    'ngInject'
                    vm = this
                    vm.title = title
                    vm.description = description
                    vm.options = options

                    vm.ok = ->
                        message = 'ok'
                        if vm.options.comment == true
                            message =
                                comment: vm.comment
                        $uibModalInstance.close message
                    vm.cancel = ->
                        $uibModalInstance.dismiss 'cancel'
                    return
                controllerAs: 'confirm'
    }

.factory 'authInterceptor', ($rootScope, $q, $location, $log, Session, EVENTS, $base64) ->
    return {
        request: (config) ->
            config.headers = config.headers || {}
            if Session.getToken()
                config.headers.Authorization = 'Basic ' + $base64.encode('web' + ':' + Session.getToken())
            $rootScope.$broadcast(EVENTS.requestStart)
            return config
        ,
        requestError: (rejection) ->
            $rootScope.$broadcast(EVENTS.connectionError)
            return $q.reject(rejection)
        ,
        responseError: (rejection) ->
            $rootScope.$broadcast(EVENTS.connectionError)
            return $q.reject(rejection)
        ,
        response: (response) ->
            $rootScope.$broadcast(EVENTS.requestEnd)
            if response.data.result == 107
                $rootScope.$broadcast(EVENTS.notAuthenticated)

            if response.data.result > 0
                $rootScope.$broadcast(EVENTS.businessError, response.data.message)

            if response.data.result < 0
                $rootScope.$broadcast(EVENTS.applicationError, response.data.message)

            return response || $q.when(response)
    }
