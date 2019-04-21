angular.module 'stock'
.controller 'DocLoadController', ($scope, $rootScope, RequestService, flowFactory, $base64, Session, toastr) ->
    'ngInject'
    vm = this
    vm.api = $rootScope.api

    initFlow = ->
        auth_token = 'Basic ' + $base64.encode('web' + ':' + Session.getToken())
        vm.flow = flowFactory.create
            target: $rootScope.api + 'upload/docs/file/' + $scope.type
            singleFile: true
            headers:
                Authorization: auth_token
            withCredentials: true
            testChunks: false
        vm.flow.on 'fileAdded', (file, event) ->
            ext = file.name.substring file.name.lastIndexOf '.'
            if ext != '.doc' and ext != '.docx'
                toastr.warning 'Выберите файл Word'
                event.preventDefault()
                return false
            if file.size > 15*1024*1024
                toastr.warning 'Файл слишком большой'
                event.preventDefault()
                return false
            return
        vm.flow.on 'filesSubmitted', (array, event) ->
            if array.length > 0
                vm.flow.upload()
            return
        vm.flow.on 'complete', ->
            vm.flow.files.clear()
            return
        vm.flow.on 'fileSuccess', (file, message, chunk) ->
            $scope.fileSrc = message
            return
        vm.flow.on 'error', (message, file, chunk) ->
            console.log message, file, chunk
            return
    initFlow()

    getFileSize = ->
        RequestService.post 'education.file_size', bobject: $scope.fileSrc
        .then (result) ->
            vm.file.size = result.bobject if vm.file
        return

    $scope.$watch 'fileSrc', (newVal) ->
        if newVal and newVal.lastIndexOf('/') > -1
            vm.file =
                name: newVal.substring 1+newVal.lastIndexOf '/'
                size: 0
            getFileSize()
        else
            delete vm.file
        return

    return
.directive 'docLoad', ->
    restrict: 'E'
    replace: true
    scope:
        fileSrc: '='
        type: '@'
    controller: 'DocLoadController'
    controllerAs: 'file'
    templateUrl: 'app/components/docLoad/doc-load.html'

.directive 'docLink', ($rootScope) ->
    restrict: 'A'
    scope:
        fileLink: '@'
    link: (scope, elem, attr) ->
        attr.$observe 'docLink', (val) ->
            if val
                scope.file_link = $rootScope.api + val
                scope.file_name = if val and val.length > 0 then val.substring(val.lastIndexOf('/') + 1) else ''
        return
    templateUrl: 'app/components/docLoad/doc-link.html'
