angular.module 'stock'
.controller 'QueueController', ($scope) ->
    'ngInject'
    vm = this
    return
.controller 'QueueListController', (RequestService, $scope, $uibModal, $translate, $state) ->
    'ngInject'
    vm = this
    vm.offset = 0
    vm.limit = 10

    vm.queueGridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs: [
            {displayName: 'Шифр', name: 'code', headerCellFilter: 'translate'}
            {displayName: 'Отрасль науки', name: 'branchesofscience.name_ru', headerCellFilter: 'translate'}
            {displayName: 'На соискание ученой степени', name: 'academicdegree.name_ru', headerCellFilter: 'translate'}
            {displayName: 'Специальность', name: 'specialty.name_ru', headerCellFilter: 'translate'}
            {displayName: 'Дата начала', name: 'date_start',type: 'date', cellFilter: 'date:\'yyyy-MM-dd\''}
            {displayName: 'Срок полномочия до', name: 'date_end', type: 'date', cellFilter: 'date:\'yyyy-MM-dd\''}
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_work = angular.copy row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getDiss()
                return

    getQueue =  ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        filter.offset = vm.offset
        filter.with_related = true
        filter.secretary = $scope.app.ua.id
        RequestService.post('queue.listing', filter).then (result) ->
            vm.diss = result.docs
            vm.queueGridOptions.data = vm.diss
            vm.queueGridOptions.totalItems = vm.diss.length
            return
        return

    newDiss = ->
        $state.go 'app.disscouncil.create'
        return

    showDiss = ->
        $state.go 'app.disscouncil.view', {disscouncil: vm.selected_work}

    vm.getQueue = getQueue
    vm.newDiss = newDiss
    vm.showDiss = showDiss

    getQueue()
    return
.controller 'QueueApplicationController', (RequestService, $scope, $uibModal, $translate, $state)->
    'ngInject'
    vm = this
    vm.offset = 0
    vm.limit = 10

    vm.applicationsGridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs: [
            {name: 'user.last_name', displayName: 'Соискатель', cellTemplate: '<span>{{row.entity.user.last_name}} {{row.entity.user.first_name}}</span>', width:180}
            {displayName: 'Дата подачи', name: 'date_app',type: 'date', cellFilter: 'amDateFormat:\'DD-MM-YYYY\''}
            {displayName: 'Дата Регистрации', name: 'date_reg',type: 'date', cellFilter: 'amDateFormat:\'DD-MM-YYYY\''}
            {displayName: 'Статус', name: 'application_status.data.name', headerCellFilter: 'translate'}
            {displayName: 'Дисс Совет', name: 'dissov.code', headerCellFilter: 'translate'}
            {displayName: 'На соискание ученой степени', name: 'theme[0].academicdegree.name_ru', headerCellFilter: 'translate'}
            {displayName: 'Отрасль науки', name: 'theme[0].branchesofscience.code', headerCellFilter: 'translate'}
            {displayName: 'Специальность', name: 'theme[0].specialty.code', headerCellFilter: 'translate'}
        ]
        events:
            onRowSelect: (row) ->
                vm.selected_application = angular.copy row.entity
                return
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getApplications()
                return

    getApplications = ->
        filter = {filter:{}}
        filter.offset = vm.offset
        filter.limit = vm.limit
        filter.with_related = true
        filter.user = $scope.app.ua.id
        RequestService.post('disapplication.listing', filter).then (result) ->
            vm.application = result.docs
            vm.applicationsGridOptions.data = vm.application
            vm.applicationsGridOptions.totalItems = vm.application.length
            return
        return

    vm.go = (path, param) ->
        $state.go path, param

    regDocument = ->
        $state.go 'app.queue.registration', {document: vm.selected_application}
        return

    vm.getApplications = getApplications
    vm.regDocument = regDocument

    getApplications()
    return

.controller 'QueueViewController', (RequestService, $scope, $uibModal, $translate, $state, $stateParams)->
    'ngInject'
    vm = this

    vm.go = (path, param) ->
        $state.go path, param

    vm.document = $stateParams.document

    if vm.document is null
        vm.go('app.queue.application')
        return

    console.log "APPLICATION", vm.document
    return
.controller 'QueueRegistrationController', (RequestService, $scope, $uibModal, $translate, $state, $stateParams)->
    'ngInject'
    vm = this
    vm.today = new Date()
    vm.offset = 0
    vm.limit = 10
    vm.degree = null
    vm.degrees = []

    vm.go = (path, param) ->
        $state.go path, param

    vm.document = $stateParams.document

    if vm.document is null
        vm.go('app.queue.application')
        return

    saveRegistration = ->
        vm.document.date_reg = vm.today
        vm.document.status = 'registration'
        RequestService.post('disapplication.update', vm.document).then (result) ->
            if result
                $state.go 'app.queue.application'
        return

    vm.saveRegistration = saveRegistration
    return

.controller 'QueueProtocolController', (RequestService, $scope, $uibModal, $translate, $state, $stateParams)->
    'ngInject'
    vm = this
    vm.remark = false
    vm.foreigner_flag = null
    vm.foreigner = null
    vm.today = new Date()
    vm.offset = 0
    vm.limit = 10
    vm.degree = null
    vm.oppenets = []
    vm.diss_users = []
    vm.filter = {}
    vm.preview =
        date: new Date()
    vm.comopinion =
        date: new Date()
    vm.prejudice =
        date: new Date()
    vm.sequencing =
        date: new Date()
    vm.protection =
        date: new Date()
    vm.remark_document =
        date: new Date()
    vm.f_data = {}

    vm.go = (path, param) ->
        $state.go path, param

    vm.document = $stateParams.document

    if vm.document is null
        vm.go('app.queue.application')
    else if vm.document != null and  vm.document.status == 'registration'
        vm.filter.dissov_id = vm.document.dissov_id
        vm.filter.with_related = true
        RequestService.post('dcomposition.listing', vm.filter).then (result) ->
            vm.users = result.docs

    savePreview = ->
        vm.document.preview.push(vm.preview)
        vm.document.status = 'comopinion'
        vm.document.excomposition = vm.diss_users
        RequestService.post('disapplication.update', vm.document).then (result) ->
            if result
                $state.go 'app.queue.application'
        return

    saveComopinion = ->
        vm.document.comopinion.push(vm.comopinion)
        vm.document.status = 'prejudice'
        RequestService.post('disapplication.update', vm.document).then (result) ->
            if result
                $state.go 'app.queue.application'
        return

    addUser = ->
        vm.diss_users.push vm.composition
        vm.composition = {}
        return

    addOpponent = ->
        vm.f_data =
            academicdegree: vm.opponent.academicdegree,
            branchesofscience: vm.opponent.branchesofscience,
            specialty: vm.opponent.specialty,
            academicrank: vm.opponent.academicrank,
            user:
                name: vm.opponent.user.name,
                user_id: vm.opponent.user.id
        vm.oppenets.push vm.f_data
        console.log(vm.oppenets)
        vm.opponent = {}
        return

    removeUser = (index) ->
        vm.diss_users.splice index, 1
        return

    editForeigner = (identity)->
        vm.foreigner_flag = identity
        return

    addForeigner = (foreigner)->
        vm.f_data =
            academicdegree: foreigner.academicdegree,
            branchesofscience: foreigner.branchesofscience,
            specialty: foreigner.specialty,
            academicrank: foreigner.academicrank,
            user:
                name: foreigner.user.name,
                user_id: null
        vm.oppenets.push vm.f_data
        vm.foreigner = null
        vm.foreigner_flag = null
        vm.f_data = {}
        return

    savePrejudice = ->
        vm.document.oppenets = vm.oppenets
        vm.document.organization_id = vm.foreigner.organization.organization_id
        vm.document.prejudice = vm.prejudice
        vm.document.status = 'sequencing'
        RequestService.post('disapplication.update', vm.document).then (result) ->
            if result
                $state.go 'app.queue.application'
        return

    saveSequencing = ->
        vm.document.sequencing = vm.sequencing
        vm.document.status = 'protection'
        RequestService.post('disapplication.update', vm.document).then (result) ->
            if result
                $state.go 'app.queue.application'
        return

    saveProtection = ->
        vm.document.protection = vm.protection
        vm.document.status = 'protection'
        RequestService.post('disapplication.update', vm.document).then (result) ->
            if result
                $state.go 'app.queue.application'
        return

    eventRemark = (value)->
        if value == 'true'
            vm.remark = true
        else
            vm.remark = false
        return

    saveRemark = ->
        vm.remark_document.dissov_id = vm.document.dissov_id
        vm.remark_document.document_id = vm.document.document_id
        vm.remark_document.user_id = $scope.app.ua.id
        vm.remark_document.status = 'new'
        vm.remark_document.disapp_status = vm.document.status
        RequestService.post('remark.save', vm.remark_document).then (result) ->
            if result
                $state.go 'app.queue.application'
        return

    vm.savePreview = savePreview
    vm.saveComopinion = saveComopinion
    vm.addUser = addUser
    vm.removeUser = removeUser
    vm.addOpponent = addOpponent
    vm.editForeigner = editForeigner
    vm.addForeigner = addForeigner
    vm.savePrejudice = savePrejudice
    vm.saveSequencing = saveSequencing
    vm.saveProtection = saveProtection
    vm.eventRemark = eventRemark
    vm.saveRemark = saveRemark
    return
