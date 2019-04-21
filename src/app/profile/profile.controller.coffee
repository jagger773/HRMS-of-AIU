angular.module 'stock'
.controller 'ProfileController', ($scope) ->
    'ngInject'
    vm = this
    return
.controller 'ProfileEditController', ($scope, $state, RequestService, $uibModal, $uibModalStack, toastr, Session, flowFactory, $stateParams) ->
    'ngInject'
    vm = this
    vm.today = new Date()
    if $stateParams.profile != null
        vm.profile = $stateParams.profile
    else
        $state.go 'app.profile.view'

    vm.education = null

    imageSelected = (event, $flow, flowFile)->
        if !flowFile.file.type.startsWith('image/')
            toastr.warning 'Выберите изображение'
            event.preventDefault()
            return false
        avatarModal = $uibModal.open
            templateUrl: 'app/profile/avatar.html'
            controller: 'AvatarEditController'
            controllerAs: 'avatar'
            size: 'lg'
            resolve:
                image: flowFile.file
        avatarModal.result.then (image)->
            $flow.cancel()
            RequestService.post 'upload/user/' + vm.profile.id, {file: image}
            .then (result)->
                vm.profile.data.image = 'image/' + result.file
                return
            return
        , (result)->
            $flow.cancel()
            return
        return

    isEdited = ->
        if angular.isUndefined $scope.app.ua
            return false
        if !angular.equals vm.profile.username, $scope.app.ua.username
            return true
        if !angular.equals vm.profile.email, $scope.app.ua.email
            return true
        if !angular.equals vm.profile.data, $scope.app.ua.data
            return true

    canChangePassword = ->
        angular.isDefined(vm.profile.password) && passwordConfirmed()

    passwordConfirmed = ->
        if (angular.isDefined vm.profile.new_password) && vm.profile.new_password.length >= 6
            return angular.equals vm.profile.new_password, vm.profile.confirm_password
        return false

    passwordLevel = ->
        if angular.isUndefined vm.profile.new_password
            return 0
        hasCaps = /[A-Z]/.test(vm.profile.new_password)
        hasNumber = /\d/.test(vm.profile.new_password)
        length = vm.profile.new_password.length
        return if length < 6 then 0 else if hasCaps && hasNumber && length > 8 then 3 else if ((hasCaps || hasNumber) && length > 8) || ((hasCaps && hasNumber) || length > 8) then 2 else 1

    putData = ->
        RequestService.post 'user.put', vm.profile
        .then (result) ->
            vm.profile = result.user
            Session.setUser(result.user)
            $scope.app.ua = Session.getUser()
            $state.go 'app.profile.view'
            toastr.success 'Изменения сохранены'
            return

    changePassword = ->
        if !canChangePassword()
            return
        RequestService.post 'user.secure', vm.profile
        .then (result) ->
            vm.profile = $scope.app.ua
            return

    openDatePicker = ->
        vm.datepicker_opened = !vm.datepicker_opened
        return


    vm.imageSelected = imageSelected
    vm.isEdited = isEdited
    vm.canChangePassword = canChangePassword
    vm.passwordLevel = passwordLevel
    vm.passwordConfirmed = passwordConfirmed
    vm.putData = putData
    vm.changePassword = changePassword
    vm.openDatePicker = openDatePicker

    return
.controller 'ProfileViewController', ($rootScope,$base64, $scope, $state, RequestService, $uibModal, $uibModalStack, toastr, Session, flowFactory) ->
    'ngInject'
    vm = this
    vm.today = new Date()
    vm.education = null
    vm.work = null
    vm.scientificwork = null
    vm.files = {}

    getUserdegrees = () ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        filter.user_id = $scope.app.ua.id
        filter.with_related = true
        filter.limit = vm.limit
        filter.offset = vm.offset
        RequestService.post('degree.listing', filter)
        .then (response) ->
            vm.userdegrees = response.docs
            vm.userdegrees_count = vm.userdegrees.length
            console.log(vm.userdegrees)
            if vm.userdegrees == []
                vm.show = true
                console.log(vm.show)
            else
                vm.show = false
                console.log(vm.show)
            return
        return


    getProfile = ->
        RequestService.post 'user.get', {id:$scope.app.ua.id}
        .then (result) ->
            vm.profile = result.user
            return

    getEducation = ->
        filter =
            user_id: $scope.app.ua.id
            with_related: true
        RequestService.post 'education.listing', filter
        .then (result) ->
            vm.educations = result.docs
            return

    putDataEducation = ->
        vm.education.user_id =  $scope.app.ua.id
        RequestService.post 'education.save', vm.education
        .then (result) ->
            vm.education = null
            getEducation()
            toastr.success 'Изменения сохранены'
            return

    editEducation = (identity) ->
        vm.education = identity
        return

    cancelEducation = () ->
        vm.education = null
        return

    removeEducation = (index) ->
        vm.educations.splice index, 1
        return

    deleteEducation = (item)->
        RequestService.post('education.delete', item)
        .then (data) ->
            getEducation()
            return

    confirmAction = (education)->
        editModal = $uibModal.open
            templateUrl: 'app/modals/confirmation-dialog.html'
            controller: 'ProfileDialogController'
            controllerAs: 'profile_dialog'
            size: 'sm'
            resolve:
                text: {text: ", что хотите удалить"}
        editModal.result.then((result)->
            if result
                deleteEducation(education)
            return
        )
        return

    getWork = ->
        filter =
            user_id: $scope.app.ua.id
            with_related: true
        RequestService.post 'work.listing', filter
        .then (result) ->
            vm.works = result.docs
            return

    putDataWork = ->
        vm.work.user_id =  $scope.app.ua.id
        RequestService.post 'work.save', vm.work
        .then (result) ->
            vm.work = null
            getWork()
            toastr.success 'Изменения сохранены'
            return

    editWork = (identity) ->
        vm.work = identity
        return

    cancelWork = () ->
        vm.work = null
        return

    removeWork = (index) ->
        vm.works.splice index, 1
        return

    deleteWork = (item)->
        RequestService.post('work.delete', item)
        .then (data) ->
            getWork()
            return

    confirmActionWork = (Work)->
        editModal = $uibModal.open
            templateUrl: 'app/modals/confirmation-dialog.html'
            controller: 'ProfileDialogController'
            controllerAs: 'profile_dialog'
            size: 'sm'
            resolve:
                text: {text: ", что хотите удалить"}
        editModal.result.then((result)->
            if result
                deleteWork(Work)
            return
        )
        return

    openDatePicker = ->
        vm.datepicker_opened = !vm.datepicker_opened
        return

    putDataDegree = ->
        vm.degree.user_id =  $scope.app.ua.id
        RequestService.post 'degree.save', vm.degree
        .then (result) ->
            vm.degree = null
            getDegree()
            toastr.success 'Изменения сохранены'
            return

    editDegree = (identity) ->
        vm.degree = identity
        return

    cancelDegree = () ->
        vm.degree = null
        return

    removeDegree = (item) ->
        RequestService.post('degree.delete', item)
        .then (data) ->
            getDegree()
            return


    confirmActionDegree = (degree)->
        editModal = $uibModal.open
            templateUrl: 'app/modals/confirmation-dialog.html'
            controller: 'ProfileDialogController'
            controllerAs: 'profile_dialog'
            size: 'sm'
            resolve:
                text: {text: ", что хотите удалить"}
        editModal.result.then((result)->
            if result
                removeDegree(degree)
            return
        )
        return

    getRank = ->
        filter =
            user_id: $scope.app.ua.id
            with_related: true
        RequestService.post 'rank.listing', filter
        .then (result) ->
            vm.ranks = result.docs
            vm.ranks_count = vm.ranks.length
            return

    putDataRank = ->
        vm.rank.user_id =  $scope.app.ua.id
        RequestService.post 'rank.save', vm.rank
        .then (result) ->
            vm.rank = null
            getRank()
            toastr.success 'Изменения сохранены'
            return

    editRank = (identity) ->
        vm.rank = identity
        return

    cancelRank = () ->
        vm.rank = null
        return

    removeRank = (item) ->
        RequestService.post('rank.delete', item)
        .then (data) ->
            getRank()
            return


    confirmActionRank = (rank)->
        editModal = $uibModal.open
            templateUrl: 'app/modals/confirmation-dialog.html'
            controller: 'ProfileDialogController'
            controllerAs: 'profile_dialog'
            size: 'sm'
            resolve:
                text: {text: ", что хотите удалить"}
        editModal.result.then((result)->
            if result
                removeRank(rank)
            return
        )
        return

    editProfile = ->
        $state.go 'app.profile.edit', {profile:vm.profile}
        return

    editScientificwork = (identity) ->
        vm.scientificwork = identity
        return

    vm.person = ''
    addCoauthor = ->
        if vm.scientificwork.coauthor is null || vm.scientificwork.coauthor is undefined
            vm.scientificwork.coauthor = []
        else
            if vm.scientificwork.coauthor.includes(vm.person)
                toastr.warning("This element is already in list ! ! !")
                return

        if vm.person isnt null and vm.person isnt undefined and vm.person isnt ''
            vm.scientificwork.coauthor.push(vm.person)
            vm.person = ''
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deleteCoauthor = (index) ->
        vm.scientificwork.coauthor.splice(index,1)
        return

    putDataScientificwork = ->
        vm.scientificwork.user_id =  $scope.app.ua.id
        RequestService.post 'scientificwork.save', vm.scientificwork
        .then (result) ->
            vm.scientificwork = null
            getScientificwork()
            toastr.success 'Изменения сохранены'
            return
        return

    getScientificwork = ->
        filter =
            user_id: $scope.app.ua.id
            with_related: true
        RequestService.post 'scientificwork.listing', filter
        .then (result) ->
            vm.scientificworks = result.docs
            return

    removeScientificwork = (item) ->
        RequestService.post('scientificwork.delete', item)
        .then (data) ->
            getScientificwork()
            return


    confirmActionScientificwork = (scientificwork)->
        editModal = $uibModal.open
            templateUrl: 'app/modals/confirmation-dialog.html'
            controller: 'ProfileDialogController'
            controllerAs: 'profile_dialog'
            size: 'sm'
            resolve:
                text: {text: ", что хотите удалить"}
        editModal.result.then((result)->
            if result
                removeScientificwork(scientificwork)
            return
        )
        return

    cancelScientificwork = ->
        vm.scientificwork = null
        return

    vm.putDataEducation = putDataEducation
    vm.getEducation = getEducation
    vm.editEducation = editEducation
    vm.removeEducation = removeEducation
    vm.cancelEducation = cancelEducation

    vm.getWork = getWork
    vm.putDataWork = putDataWork
    vm.editWork = editWork
    vm.cancelWork = cancelWork
    vm.removeWork = removeWork
    vm.deleteWork = deleteWork
    vm.confirmAction = confirmAction
    vm.confirmActionWork = confirmActionWork

    vm.confirmActionDegree = confirmActionDegree
    vm.openDatePicker = openDatePicker
    vm.putDataDegree = putDataDegree
    vm.editDegree = editDegree
    vm.cancelDegree = cancelDegree
    vm.removeDegree = removeDegree

    vm.getRank = getRank
    vm.putDataRank = putDataRank
    vm.editRank = editRank
    vm.cancelRank = cancelRank
    vm.removeRank = removeRank
    vm.confirmActionRank = confirmActionRank

    vm.editProfile = editProfile
    vm.getUserdegrees = getUserdegrees
    vm.getProfile = getProfile

    vm.editScientificwork = editScientificwork
    vm.addCoauthor = addCoauthor
    vm.deleteCoauthor = deleteCoauthor
    vm.getScientificwork = getScientificwork
    vm.putDataScientificwork = putDataScientificwork
    vm.confirmActionScientificwork = confirmActionScientificwork
    vm.cancelScientificwork = cancelScientificwork

    getScientificwork()
    getUserdegrees()
    getRank()
    getEducation()
    getWork()
    getProfile()
    return
.controller 'AvatarEditController', ($scope, image, $uibModalInstance) ->
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
.controller 'ProfileDialogController', ($scope, hotkeys, $state, RequestService, text, Session, $filter, toastr, $stateParams, $uibModalInstance) ->
    'ngInject'
    vm = this
    vm.text = text || ''
    ok = ->
        $uibModalInstance.close true
        return

    cancel = ->
        $uibModalInstance.close false
        return

    vm.ok = ok
    vm.cancel = cancel
    return
.controller 'ProfilePreregistrationController', ($rootScope,$base64, $scope, $state, RequestService, $uibModal, $uibModalStack, toastr, Session, flowFactory) ->
    'ngInject'
    vm = this
    vm.today = new Date()
    vm.education = null
    vm.work = null
    vm.scientificwork = null
    vm.files = {}
    vm.education = null
    vm.profile = $scope.app.ua

    imageSelected = (event, $flow, flowFile)->
        if !flowFile.file.type.startsWith('image/')
            toastr.warning 'Выберите изображение'
            event.preventDefault()
            return false
        avatarModal = $uibModal.open
            templateUrl: 'app/profile/avatar.html'
            controller: 'AvatarEditController'
            controllerAs: 'avatar'
            size: 'lg'
            resolve:
                image: flowFile.file
        avatarModal.result.then (image)->
            $flow.cancel()
            RequestService.post 'upload/user/' + vm.profile.id, {file: image}
            .then (result)->
                vm.profile.data.image = 'image/' + result.file
                return
            return
        , (result)->
            $flow.cancel()
            return
        return

    isEdited = ->
        if angular.isUndefined $scope.app.ua
            return false
        if !angular.equals vm.profile.username, $scope.app.ua.username
            return true
        if !angular.equals vm.profile.email, $scope.app.ua.email
            return true
        if !angular.equals vm.profile.data, $scope.app.ua.data
            return true

    canChangePassword = ->
        angular.isDefined(vm.profile.password) && passwordConfirmed()

    passwordConfirmed = ->
        if (angular.isDefined vm.profile.new_password) && vm.profile.new_password.length >= 6
            return angular.equals vm.profile.new_password, vm.profile.confirm_password
        return false

    passwordLevel = ->
        if angular.isUndefined vm.profile.new_password
            return 0
        hasCaps = /[A-Z]/.test(vm.profile.new_password)
        hasNumber = /\d/.test(vm.profile.new_password)
        length = vm.profile.new_password.length
        return if length < 6 then 0 else if hasCaps && hasNumber && length > 8 then 3 else if ((hasCaps || hasNumber) && length > 8) || ((hasCaps && hasNumber) || length > 8) then 2 else 1

    putData = ->
        RequestService.post 'user.put', vm.profile
        .then (result) ->
            vm.profile = result.user
            Session.setUser(result.user)
            $scope.app.ua = Session.getUser()
            toastr.success 'Изменения сохранены'
            return

    changePassword = ->
        if !canChangePassword()
            return
        RequestService.post 'user.secure', vm.profile
        .then (result) ->
            vm.profile = $scope.app.ua
            return

    openDatePicker = ->
        vm.datepicker_opened = !vm.datepicker_opened
        return


    getUserdegrees = () ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        filter.user_id = $scope.app.ua.id
        filter.with_related = true
        filter.limit = vm.limit
        filter.offset = vm.offset
        RequestService.post('degree.listing', filter)
        .then (response) ->
            vm.userdegrees = response.docs
            return
        return

    getProfile = ->
        RequestService.post 'user.get', {id:$scope.app.ua.id}
        .then (result) ->
            vm.profile = result.user
            return

    getEducation = ->
        filter =
            user_id: $scope.app.ua.id
            with_related: true
        RequestService.post 'education.listing', filter
        .then (result) ->
            vm.educations = result.docs
            return

    putDataEducation = ->
        vm.education.user_id =  $scope.app.ua.id
        RequestService.post 'education.save', vm.education
        .then (result) ->
            vm.education = null
            getEducation()
            toastr.success 'Изменения сохранены'
            return

    editEducation = (identity) ->
        vm.education = identity
        return

    cancelEducation = () ->
        vm.education = null
        return

    removeEducation = (index) ->
        vm.educations.splice index, 1
        return

    deleteEducation = (item)->
        RequestService.post('education.delete', item)
        .then (data) ->
            getEducation()
            return

    confirmAction = (education)->
        editModal = $uibModal.open
            templateUrl: 'app/modals/confirmation-dialog.html'
            controller: 'ProfileDialogController'
            controllerAs: 'profile_dialog'
            size: 'sm'
            resolve:
                text: {text: ", что хотите удалить"}
        editModal.result.then((result)->
            if result
                deleteEducation(education)
            return
        )
        return

    getWork = ->
        filter =
            user_id: $scope.app.ua.id
            with_related: true
        RequestService.post 'work.listing', filter
        .then (result) ->
            vm.works = result.docs
            return

    putDataWork = ->
        vm.work.user_id =  $scope.app.ua.id
        RequestService.post 'work.save', vm.work
        .then (result) ->
            vm.work = null
            getWork()
            toastr.success 'Изменения сохранены'
            return

    editWork = (identity) ->
        vm.work = identity
        return

    cancelWork = () ->
        vm.work = null
        return

    removeWork = (index) ->
        vm.works.splice index, 1
        return

    deleteWork = (item)->
        RequestService.post('work.delete', item)
        .then (data) ->
            getWork()
            return

    confirmActionWork = (Work)->
        editModal = $uibModal.open
            templateUrl: 'app/modals/confirmation-dialog.html'
            controller: 'ProfileDialogController'
            controllerAs: 'profile_dialog'
            size: 'sm'
            resolve:
                text: {text: ", что хотите удалить"}
        editModal.result.then((result)->
            if result
                deleteWork(Work)
            return
        )
        return

    openDatePicker = ->
        vm.datepicker_opened = !vm.datepicker_opened
        return

    putDataDegree = ->
        vm.degree.user_id =  $scope.app.ua.id
        RequestService.post 'degree.save', vm.degree
        .then (result) ->
            vm.degree = null
            getDegree()
            toastr.success 'Изменения сохранены'
            return

    editDegree = (identity) ->
        vm.degree = identity
        return

    cancelDegree = () ->
        vm.degree = null
        return

    removeDegree = (item) ->
        RequestService.post('degree.delete', item)
        .then (data) ->
            getDegree()
            return


    confirmActionDegree = (degree)->
        editModal = $uibModal.open
            templateUrl: 'app/modals/confirmation-dialog.html'
            controller: 'ProfileDialogController'
            controllerAs: 'profile_dialog'
            size: 'sm'
            resolve:
                text: {text: ", что хотите удалить"}
        editModal.result.then((result)->
            if result
                removeDegree(degree)
            return
        )
        return

    getRank = ->
        filter =
            user_id: $scope.app.ua.id
            with_related: true
        RequestService.post 'rank.listing', filter
        .then (result) ->
            vm.ranks = result.docs
            return

    putDataRank = ->
        vm.rank.user_id =  $scope.app.ua.id
        RequestService.post 'rank.save', vm.rank
        .then (result) ->
            vm.rank = null
            getRank()
            toastr.success 'Изменения сохранены'
            return

    editRank = (identity) ->
        vm.rank = identity
        return

    cancelRank = () ->
        vm.rank = null
        return

    removeRank = (item) ->
        RequestService.post('rank.delete', item)
        .then (data) ->
            getRank()
            return


    confirmActionRank = (rank)->
        editModal = $uibModal.open
            templateUrl: 'app/modals/confirmation-dialog.html'
            controller: 'ProfileDialogController'
            controllerAs: 'profile_dialog'
            size: 'sm'
            resolve:
                text: {text: ", что хотите удалить"}
        editModal.result.then((result)->
            if result
                removeRank(rank)
            return
        )
        return

    editProfile = ->
        $state.go 'app.profile.edit', {profile:vm.profile}
        return

    editScientificwork = (identity) ->
        vm.scientificwork = identity
        return

    vm.person = ''
    addCoauthor = ->
        if vm.scientificwork.coauthor is null || vm.scientificwork.coauthor is undefined
            vm.scientificwork.coauthor = []
        else
            if vm.scientificwork.coauthor.includes(vm.person)
                toastr.warning("This element is already in list ! ! !")
                return

        if vm.person isnt null and vm.person isnt undefined and vm.person isnt ''
            vm.scientificwork.coauthor.push(vm.person)
            vm.person = ''
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deleteCoauthor = (index) ->
        vm.scientificwork.coauthor.splice(index,1)
        return

    putDataScientificwork = ->
        vm.scientificwork.user_id =  $scope.app.ua.id
        RequestService.post 'scientificwork.save', vm.scientificwork
        .then (result) ->
            vm.scientificwork = null
            getScientificwork()
            toastr.success 'Изменения сохранены'
            return
        return

    getScientificwork = ->
        filter =
            user_id: $scope.app.ua.id
            with_related: true
        RequestService.post 'scientificwork.listing', filter
        .then (result) ->
            vm.scientificworks = result.docs
            return

    removeScientificwork = (item) ->
        RequestService.post('scientificwork.delete', item)
        .then (data) ->
            getScientificwork()
            return


    confirmActionScientificwork = (scientificwork)->
        editModal = $uibModal.open
            templateUrl: 'app/modals/confirmation-dialog.html'
            controller: 'ProfileDialogController'
            controllerAs: 'profile_dialog'
            size: 'sm'
            resolve:
                text: {text: ", что хотите удалить"}
        editModal.result.then((result)->
            if result
                removeScientificwork(scientificwork)
            return
        )
        return

    cancelScientificwork = ->
        vm.scientificwork = null
        return

    confirmActionFinish = ->
        $state.go 'app.profile.view'
        return

    vm.imageSelected = imageSelected
    vm.isEdited = isEdited
    vm.canChangePassword = canChangePassword
    vm.passwordLevel = passwordLevel
    vm.passwordConfirmed = passwordConfirmed
    vm.putData = putData
    vm.changePassword = changePassword
    vm.openDatePicker = openDatePicker
    vm.putDataEducation = putDataEducation
    vm.getEducation = getEducation
    vm.editEducation = editEducation
    vm.removeEducation = removeEducation
    vm.cancelEducation = cancelEducation

    vm.getWork = getWork
    vm.putDataWork = putDataWork
    vm.editWork = editWork
    vm.cancelWork = cancelWork
    vm.removeWork = removeWork
    vm.deleteWork = deleteWork
    vm.confirmAction = confirmAction
    vm.confirmActionWork = confirmActionWork

    vm.confirmActionDegree = confirmActionDegree
    vm.openDatePicker = openDatePicker
    vm.putDataDegree = putDataDegree
    vm.editDegree = editDegree
    vm.cancelDegree = cancelDegree
    vm.removeDegree = removeDegree

    vm.getRank = getRank
    vm.putDataRank = putDataRank
    vm.editRank = editRank
    vm.cancelRank = cancelRank
    vm.removeRank = removeRank
    vm.confirmActionRank = confirmActionRank

    vm.editProfile = editProfile
    vm.getUserdegrees = getUserdegrees
    vm.getProfile = getProfile

    vm.editScientificwork = editScientificwork
    vm.addCoauthor = addCoauthor
    vm.deleteCoauthor = deleteCoauthor
    vm.getScientificwork = getScientificwork
    vm.putDataScientificwork = putDataScientificwork
    vm.confirmActionScientificwork = confirmActionScientificwork
    vm.cancelScientificwork = cancelScientificwork

    vm.confirmActionFinish = confirmActionFinish

    getScientificwork()
    getUserdegrees()
    getRank()
    getEducation()
    getWork()
    getProfile()
    return
