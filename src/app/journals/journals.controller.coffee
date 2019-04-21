angular.module 'stock'
.controller 'JournalsController', ($rootScope, $scope, $state, RequestService) ->
    'ngInject'
    return
.controller 'JournalsListController', ($rootScope, $scope, $state, RequestService, $translate) ->
    'ngInject'
    vm = this
    vm.journals = []
    vm.lang =  $translate.use().valueOf()

    vm.journalGridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs: [
            { displayName: 'NAME_RU_SPAN_LABEL', name: 'name_ru', headerCellFilter: 'translate'}
            {name: 'name_kg', displayName: 'FIO_LABEL', cellTemplate: '<span> {{row.entity.name_[vm.lang]}} </span>', headerCellFilter: 'translate'}
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_journal = angular.copy row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getJournals()
                return

    getJournals = () ->
        RequestService.post('journals.listing')
        .then (response) ->
            vm.journals = response.docs
            vm.journalGridOptions.data = vm.journals
            vm.journalGridOptions.totalItems = vm.journals.length
            return
        return

    go = (path, param) ->
        console.log "GOING TO " + path
        $state.go path, param

    getCurrentLang = ->
        return $translate

    vm.getJournals = getJournals
    vm.getCurrentLang = getCurrentLang
    vm.go = go
    getJournals()

    return

.controller 'JournalsFormController', ($rootScope, $scope, $state, $stateParams, RequestService, $uibModal) ->
    'ngInject'
    vm = this

    vm.journal = $stateParams.journal
    vm.isSaving = false

    imageSelected = (event, $flow, flowFile)->
        if !flowFile.file.type.startsWith('image/')
            toastr.warning 'Выберите изображение'
            event.preventDefault()
            return false
        avatarModal = $uibModal.open
            templateUrl: 'app/journals/cover.html'
            controller: 'JournalsCoverController'
            controllerAs: 'cover'
            size: 'lg'
            resolve:
                image: flowFile.file
        avatarModal.result.then (image)->
            $flow.cancel()
            RequestService.post 'upload/journal/' + $scope.app.ua.id, {file: image}
            .then (result)->
                vm.journal.img_url = 'image/' + result.file
                return
            return
        , (result)->
            $flow.cancel()
            return
        return

    toast = (result)->
        if result.result > 0
            toastr.warning result.message
        else if result.result < 0
            toastr.error result.message

    saveJournal = ->
        vm.isSaving = true
        console.log vm.journal
        RequestService.post('journals.save', vm.journal)
        .then((response) ->
            vm.isSaving = false
            console.log(response)
            goBack()
            return
        (result) ->
            vm.isSaving = false
            console.log(result)
            toast if result then result else result:-1,message: 'Ошибка сети'
            return)
        return

    goBack = ->
        $state.go('app.journals.list')
        return

    vm.saveJournal = saveJournal
    vm.goBack = goBack
    vm.imageSelected = imageSelected
    return

.controller 'JournalsCoverController', ($scope, image, $uibModalInstance) ->
    'ngInject'
    vm = this
    vm.image = ''
    vm.result_image = ''

    readFile = ->
        if angular.isUndefined image
            return
        vm.imageLoading = true
        reader = new FileReader()
        reader.onload = (event)->
            $scope.$apply ($scope)->
                vm.imageLoading = false
                vm.image = event.target.result
                return
            return
        reader.readAsDataURL image

    vm.ok = ->
        $uibModalInstance.close vm.result_image
        return

    vm.cancel = ->
        $uibModalInstance.dismiss 'cancel'
        return

    readFile()
    return
.controller 'JournalsViewController', ($rootScope, $scope, $state, $stateParams) ->
    'ngInject'
    vm = this

    goBack = ->
        $state.go('app.journals.list')
        return

    vm.journal = $stateParams.journal

    if Object.keys(vm.journal).length == 0
        goBack()
        return

    vm.goBack = goBack

    return
