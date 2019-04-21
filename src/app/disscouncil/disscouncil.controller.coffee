angular.module 'stock'
.controller 'DisscouncilController', ($scope) ->
    'ngInject'
    vm = this
    return
.controller 'DisscouncilListController', (RequestService, $scope, $uibModal, $translate, $state) ->
    'ngInject'
    vm = this
    vm.selected_work = null

    getDiss =  ->
        filter = {filter:{}}
        if !filter.filter
            filter.filter = {}
        filter.offset = vm.offset
        filter.with_related = true
        RequestService.post('dissov.listing', filter).then (result) ->
            vm.diss = result.docs
            vm.totalItems = vm.diss.length
        return

    newDiss = ->
        $state.go 'app.disscouncil.create'
        return

    rowValue = (tr) ->
        vm.selected_work = tr
        return

    isSelected =(row) ->
        if row == vm.selected_work
            return true
        else
            return false
        return

    removeDiss = ->
        return if not vm.selected_work
        vm.selected_work.crud = 'Dissov'
        RequestService.post 'dissov/remove', vm.selected_work
        .then (result) ->
            if result.deleted == 'ok'
                getDiss()
            return
        return

    showDiss =() ->
        $state.go 'app.disscouncil.view', {disscouncil: vm.selected_work}

    editDiss =() ->
        $state.go 'app.disscouncil.edit', {disscouncil: vm.selected_work}

    vm.removeDiss = removeDiss
    vm.getDiss = getDiss
    vm.newDiss = newDiss
    vm.rowValue = rowValue
    vm.isSelected = isSelected
    vm.showDiss = showDiss
    vm.editDiss = editDiss

    getDiss()
    return
.controller 'DisscouncilCreateController', ($rootScope, RequestService, $scope, $uibModal, $translate, $state, toastr, $location) ->
    'ngInject'
    vm = this
    vm.today = new Date()
    vm.diss =
        date_start: new Date()
        date_end: moment(vm.today).add(768, 'day').toDate()
        data: {}
    vm.dis =
        user: {}
        refspecialty: {}
        workspecialty: {}
    vm.diss_users = []
    vm.offset = 0
    vm.limit = 10
    vm.degree = null
    vm.degrees = []
    vm.degree_academicdegree = null
    vm.degree_branchesofscience = null
    vm.degree_specialty = null


    recalculateOnEventAll = ->
        if vm.diss.date_start < vm.today
            toastr.warning("Нельзя добавлять пустое")

        vm.diss.date_end  = moment(vm.diss.date_start).add(2, 'year').toDate()
        return

    vm.degree_specialty = ''
    addDegreeSpeciality= ->
        if vm.degree_specialities is null || vm.degree_specialities is undefined
            vm.degree_specialities = []
        else
            if vm.degree_specialities.includes(vm.degree_specialty)
                toastr.warning("This element is already in list! ! !")
                return
        if vm.degree_specialty isnt null and vm.degree_specialty isnt undefined and vm.degree_specialty isnt ''
            vm.degree_specialities.push({
                name: vm.degree_specialty.code + ' - ' + vm.degree_specialty.name_ru
                specialty_id: vm.degree_specialty._id
            })
            vm.degree_specialty = ''
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deleteDegreeSpeciality = (index) ->
        vm.degree_specialities.splice(index,1)
        return

    vm.degree_branchesofscience = ''
    addDegreeBranchesofscience= ->
        if vm.degree_branchesofsciences is null || vm.degree_branchesofsciences is undefined
            vm.degree_branchesofsciences = []
        else
            if vm.degree_branchesofsciences.includes(vm.degree_branchesofscience)
                toastr.warning("This element is already in list! ! !")
                return
        if vm.degree_branchesofscience isnt null and vm.degree_branchesofscience isnt undefined and vm.degree_branchesofscience isnt ''
            vm.degree_branchesofsciences.push({
                name: vm.degree_branchesofscience.name_ru
                branchesofscience_id: vm.degree_branchesofscience._id
            })
            vm.degree_branchesofscience = ''
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deleteDegreeBranchesofscience = (index) ->
        vm.degree_branchesofsciences.splice(index,1)
        return

    editDegree = (index) ->
        disDegree = vm.degrees[index]
        console.log disDegree
        if disDegree.academicdegree == null or disDegree.academicdegree == undefined or disDegree.academicdegree == []
            vm.degree_academicdegree =  ''
        else
            vm.degree_academicdegree = disDegree.academicdegree.academicdegree_id

        if disDegree.branchesofscience == null or disDegree.branchesofscience == undefined or disDegree.branchesofscience == []
            vm.degree_branchesofscience =  ''
        else
            vm.degree_branchesofsciences = disDegree.branchesofscience
        if disDegree.specialty == null or disDegree.specialty == undefined or disDegree.specialty == []
            vm.degree_specialty  = ''
        else
            vm.degree_specialities = disDegree.specialty
        removeDegree(index)
        return

    addAddress= ->
        if vm.diss.data.addresses is null || vm.diss.data.addresses is undefined
            vm.diss.data.addresses = []
        else
            if vm.diss.data.addresses.includes(vm.address)
                toastr.warning("This element is already in list ! ! !")
                return
        if vm.address isnt null and vm.address isnt undefined and vm.address isnt ''
            vm.diss.data.addresses.push(vm.address)
            vm.address = ''
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deleteAddress = (index) ->
        vm.diss.data.addresses.splice(index,1)
        return


    vm.email = ''
    addEmail = ->
#        console.log($scope.edit.dictionary)
        if vm.diss.data.emails is null || vm.diss.data.emails is undefined
            vm.diss.data.emails = []
        else
            if vm.diss.data.emails.includes(vm.email)
                toastr.warning("This element is already in list ! ! !")
                return
        if vm.email isnt null and vm.email isnt undefined and vm.email isnt ''
            vm.diss.data.emails.push(vm.email)
            vm.email = ''
        else
            toastr.warning("Нельзя добавлять пустое")

        return

    deleteEmail = (index) ->
        vm.diss.data.emails.splice(index,1)
        return


    vm.website = ''
    addWebsite = ->
        if vm.diss.data.websites is null || vm.diss.data.websites is undefined
            vm.diss.data.websites = []
        else
            if vm.diss.data.websites.includes(vm.website)
                toastr.warning("This element is already in list ! ! !")
                return

        if vm.website isnt null and vm.website isnt undefined and vm.website isnt ''
            vm.diss.data.websites.push(vm.website)
            vm.website = ''
        else
            toastr.warning("Нельзя добавлять пустое")

        return

    deleteWebsite = (index) ->
        vm.diss.data.websites.splice(index,1)
        return

    vm.organization = null
    addOrganization = ->
        if vm.diss.organizations is null || vm.diss.organizations is undefined
            vm.diss.organizations = []
        else
            if vm.diss.organizations.includes(vm.organization)
                toastr.warning("This element is already in list ! ! !")
                return

        if vm.organization isnt null and vm.organization isnt undefined and vm.organization isnt ''
            vm.diss.organizations.push(vm.organization)
            vm.organization = null
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deleteOrganization = (index) ->
        vm.diss.organizations.splice(index,1)
        return

    vm.phone = ''
    addPhone = ->
        if vm.diss.data.phones is null || vm.diss.data.phones is undefined
            vm.diss.data.phones = []
        else
            if vm.diss.data.phones.includes(vm.phone)
                toastr.warning("This element is already in list ! ! !")
                return

        if vm.phone isnt null and vm.phone isnt undefined and vm.phone isnt ''
            vm.diss.data.phones.push(vm.phone)
            vm.phone = ''
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deletePhone = (index) ->
        vm.diss.data.phones.splice(index,1)
        return

    saveDissov = ->
        vm.diss.composition = vm.diss_users
        vm.diss.programs = vm.degrees
        RequestService.post('dissov.save', vm.diss)
        .then (response) ->
            $state.go 'app.disscouncil.list'
            toastr.success 'Тема диссертации создана'
        return

    getUsers =  ->
        RequestService.post('user.listing',{}).then (result) ->
            vm.users = result.users
            return
        return



    removeUser = (index) ->
        vm.diss_users.splice index, 1
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
                removeUser(education)
            return
        )
        return

    putDataDegree = ->
        if vm.degree_academicdegree == null or vm.degree_academicdegree == ' ' or vm.degree_academicdegree == undefined  or vm.degree_academicdegree == []
            toastr.warning('Специальность не выбрана!')
        else
            vm.degree =
                academicdegree:
                    name: vm.degree_academicdegree.name_ru
                    academicdegree_id: vm.degree_academicdegree._id
                branchesofscience: vm.degree_branchesofsciences
                specialty: vm.degree_specialities
            vm.degrees.push vm.degree
            console.log(vm.degrees)
            vm.degree_academicdegree = null
            vm.degree_branchesofscience = null
            vm.degree_specialty = null
            vm.degree = null
            vm.degree_branchesofsciences = []
            vm.degree_specialities = []
        return


    removeDegree = (index) ->
        vm.degrees.splice index, 1


    confirmActionDegree = (index)->
        editModal = $uibModal.open
            templateUrl: 'app/modals/confirmation-dialog.html'
            controller: 'ProfileDialogController'
            controllerAs: 'profile_dialog'
            size: 'sm'
            resolve:
                text: {text: ", что хотите удалить"}
        editModal.result.then((result)->
            if result
                removeDegree(index)
            return
        )
        return

    goBack = ->
        $state.go 'app.disscouncil.list'
        return

    addUser = ->
        vm.dis =
            user:
                first_name: vm.user_person.first_name
                last_name: vm.user_person.last_name
                middle_name: vm.user_person.middle_name
                birthday: vm.user_person.birthday
            user_id: vm.user_person.id
            abstract: vm.refspecialties || null
            work: vm.workspecialties || null
            role:  vm.role
        vm.diss_users.push vm.dis
        console.log "diss", vm.diss_users
        vm.user_person = null
        vm.workspecialty = null
        vm.refspecialty = null
        vm.refspecialties = []
        vm.workspecialties = []
        return

    editUser = (index) ->
        disUser = vm.diss_users[index]
        console.log disUser
        if disUser.user == null or disUser.user == undefined or disUser.user == []
            vm.user_person =  ''
        else
            vm.user_person = id: disUser.user_id

        if disUser.abstract == null or disUser.abstract == undefined or disUser.abstract == []
            vm.abstract =  ''
        else
            vm.refspecialties = disUser.abstract
        if disUser.work == null or disUser.work == undefined or disUser.work == []
            vm.work  = ''
        else
            vm.workspecialties = disUser.work
        if disUser.role == null or disUser.role == undefined
            vm.role  = ''
        else
            vm.role = disUser.role
        removeUser(index)
        return

    vm.refspecialty = null
    addRefspecialty = ->
        if vm.refspecialties is null || vm.refspecialties is undefined
            vm.refspecialties = []
        else
            if vm.refspecialties.includes(vm.refspecialty)
                toastr.warning("This element is already in list ! ! !")
                return

        if vm.refspecialty isnt null and vm.refspecialty isnt undefined and vm.refspecialty isnt ''
            vm.refspecialties.push({
                code: vm.refspecialty.code
                specialty_id: vm.refspecialty._id
            })
            console.log vm.refspecialties["0"]
            vm.refspecialty = null
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deleteRefspecialty = (index) ->
        vm.refspecialties.splice(index,1)
        return

    vm.workspecialty = null
    addWorkspecialty = ->
        if vm.workspecialties is null || vm.workspecialties is undefined
            vm.workspecialties = []
        else
            if vm.workspecialties.includes(vm.workspecialty)
                toastr.warning("This element is already in list ! ! !")
                return

        if vm.workspecialty isnt null and vm.workspecialty isnt undefined and vm.workspecialty isnt ''
            vm.workspecialties.push({
                code: vm.workspecialty.code
                specialty_id: vm.workspecialty._id
            })
            vm.workspecialty = null
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deleteWorkspecialty = (index) ->
        vm.workspecialties.splice(index,1)
        return


    vm.addWorkspecialty = addWorkspecialty
    vm.deleteWorkspecialty = deleteWorkspecialty
    vm.addRefspecialty = addRefspecialty
    vm.deleteRefspecialty = deleteRefspecialty
    vm.goBack = goBack
    vm.recalculateOnEventAll = recalculateOnEventAll
    vm.addDegreeSpeciality = addDegreeSpeciality
    vm.deleteDegreeSpeciality = deleteDegreeSpeciality
    vm.addDegreeBranchesofscience =addDegreeBranchesofscience
    vm.deleteDegreeBranchesofscience = deleteDegreeBranchesofscience
    vm.addPhone = addPhone
    vm.deletePhone = deletePhone

    vm.addWebsite = addWebsite
    vm.deleteWebsite = deleteWebsite

    vm.addEmail = addEmail
    vm.deleteEmail = deleteEmail

    vm.addAddress = addAddress
    vm.deleteAddress = deleteAddress
    vm.editUser = editUser
    vm.saveDissov = saveDissov
    vm.getUsers = getUsers
    vm.addUser = addUser
    vm.removeUser = removeUser
    vm.confirmAction = confirmAction
    vm.putDataDegree = putDataDegree
    vm.editDegree = editDegree
    vm.removeDegree = removeDegree
    vm.confirmActionDegree = confirmActionDegree
    vm.addOrganization = addOrganization
    vm.deleteOrganization = deleteOrganization

    getUsers()
    return


.controller 'DisscouncilViewController', (RequestService, $scope, $stateParams, $uibModal, $translate, $state) ->
    'ngInject'
    vm = this

    vm.go = (path, data) ->
        $state.go path, data

    vm.diss = $stateParams.disscouncil
    console.log vm.diss

    if Object.keys(vm.diss).length == 0
        vm.go('app.disscouncil.list')
        return

    vm.diss.date_start = new Date(vm.diss.date_start)
    vm.diss.date_end = new Date(vm.diss.date_end)

    return


.controller 'DisscouncilApplicationController', (RequestService, $scope, $stateParams, $uibModal, $translate, $state, Session) ->
    'ngInject'
    vm = this

    vm.go = (path, data) ->
        $state.go path, data

    vm.diss = $stateParams.disscouncil

    if Object.keys(vm.diss).length == 0
        vm.go('app.disscouncil.list')
        return

    vm.getThemes = () ->
        user = Session.getUser()
        filter = user_id: user.id
        RequestService.post 'theme.listing', {filter: filter}
        .then (response) ->
            vm.themes = response.docs

    #    vm.getDegrees = () ->
    #        filter = order_by: ["_created DESC"]
    #        RequestService.post 'degree.listing', {filter: filter}
    #        .then (result) ->
    #            vm.academic_degrees = result.docs[0]

    vm.getThemes()
    return

.controller 'DisscouncilEditController', ($rootScope, RequestService, $scope, $uibModal, $translate, $state, toastr, $location,$stateParams) ->
    'ngInject'
    vm = this
    vm.diss = $stateParams.disscouncil || []
    vm.degrees = vm.diss.programs
    vm.diss_users = vm.diss.compositions
    console.log vm.degrees

    recalculateOnEventAll = ->
        if vm.diss.date_start < vm.today
            toastr.warning("Нельзя добавлять пустое")

        vm.diss.date_end  = moment(vm.diss.date_start).add(2, 'year').toDate()
        return

    vm.degree_specialty = ''
    addDegreeSpeciality= ->
        if vm.degree_specialities is null || vm.degree_specialities is undefined
            vm.degree_specialities = []
        else
            if vm.degree_specialities.includes(vm.degree_specialty)
                toastr.warning("This element is already in list! ! !")
                return
        if vm.degree_specialty isnt null and vm.degree_specialty isnt undefined and vm.degree_specialty isnt ''
            vm.degree_specialities.push({
                name: vm.degree_specialty.code + ' - ' + vm.degree_specialty.name_ru
                specialty_id: vm.degree_specialty._id
            })
            vm.degree_specialty = ''
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deleteDegreeSpeciality = (index) ->
        vm.degree_specialities.splice(index,1)
        return

    vm.degree_branchesofscience = ''
    addDegreeBranchesofscience= ->
        if vm.degree_branchesofsciences is null || vm.degree_branchesofsciences is undefined
            vm.degree_branchesofsciences = []
        else
            if vm.degree_branchesofsciences.includes(vm.degree_branchesofscience)
                toastr.warning("This element is already in list! ! !")
                return
        if vm.degree_branchesofscience isnt null and vm.degree_branchesofscience isnt undefined and vm.degree_branchesofscience isnt ''
            vm.degree_branchesofsciences.push({
                name: vm.degree_branchesofscience.name_ru
                branchesofscience_id: vm.degree_branchesofscience._id
            })
            vm.degree_branchesofscience = ''
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deleteDegreeBranchesofscience = (index) ->
        vm.degree_branchesofsciences.splice(index,1)
        return

    editDegree = (index) ->
        disDegree = vm.degrees[index]
        console.log disDegree
        if disDegree.academicdegree == null or disDegree.academicdegree == undefined or disDegree.academicdegree == []
            vm.degree_academicdegree =  ''
        else
            vm.degree_academicdegree = disDegree.academicdegree.academicdegree_id

        if disDegree.branchesofscience == null or disDegree.branchesofscience == undefined or disDegree.branchesofscience == []
            vm.degree_branchesofscience =  ''
        else
            vm.degree_branchesofsciences = disDegree.branchesofscience
        if disDegree.specialty == null or disDegree.specialty == undefined or disDegree.specialty == []
            vm.degree_specialty  = ''
        else
            vm.degree_specialities = disDegree.specialty
        removeDegree(index)
        return

    addAddress= ->
        if vm.diss.data.addresses is null || vm.diss.data.addresses is undefined
            vm.diss.data.addresses = []
        else
            if vm.diss.data.addresses.includes(vm.address)
                toastr.warning("This element is already in list ! ! !")
                return
        if vm.address isnt null and vm.address isnt undefined and vm.address isnt ''
            vm.diss.data.addresses.push(vm.address)
            vm.address = ''
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deleteAddress = (index) ->
        vm.diss.data.addresses.splice(index,1)
        return


    vm.email = ''
    addEmail = ->
#        console.log($scope.edit.dictionary)
        if vm.diss.data.emails is null || vm.diss.data.emails is undefined
            vm.diss.data.emails = []
        else
            if vm.diss.data.emails.includes(vm.email)
                toastr.warning("This element is already in list ! ! !")
                return
        if vm.email isnt null and vm.email isnt undefined and vm.email isnt ''
            vm.diss.data.emails.push(vm.email)
            vm.email = ''
        else
            toastr.warning("Нельзя добавлять пустое")

        return

    deleteEmail = (index) ->
        vm.diss.data.emails.splice(index,1)
        return


    vm.website = ''
    addWebsite = ->
        if vm.diss.data.websites is null || vm.diss.data.websites is undefined
            vm.diss.data.websites = []
        else
            if vm.diss.data.websites.includes(vm.website)
                toastr.warning("This element is already in list ! ! !")
                return

        if vm.website isnt null and vm.website isnt undefined and vm.website isnt ''
            vm.diss.data.websites.push(vm.website)
            vm.website = ''
        else
            toastr.warning("Нельзя добавлять пустое")

        return

    deleteWebsite = (index) ->
        vm.diss.data.websites.splice(index,1)
        return

    vm.organization = null
    addOrganization = ->
        if vm.diss.organizations is null || vm.diss.organizations is undefined
            vm.diss.organizations = []
        else
            if vm.diss.organizations.includes(vm.organization)
                toastr.warning("This element is already in list ! ! !")
                return

        if vm.organization isnt null and vm.organization isnt undefined and vm.organization isnt ''
            vm.diss.organizations.push(vm.organization)
            vm.organization = null
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deleteOrganization = (index) ->
        vm.diss.organizations.splice(index,1)
        return

    vm.phone = ''
    addPhone = ->
        if vm.diss.data.phones is null || vm.diss.data.phones is undefined
            vm.diss.data.phones = []
        else
            if vm.diss.data.phones.includes(vm.phone)
                toastr.warning("This element is already in list ! ! !")
                return

        if vm.phone isnt null and vm.phone isnt undefined and vm.phone isnt ''
            vm.diss.data.phones.push(vm.phone)
            vm.phone = ''
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deletePhone = (index) ->
        vm.diss.data.phones.splice(index,1)
        return

    saveDissov = ->
        vm.diss.composition = vm.diss_users
        vm.diss.programs = vm.degrees
        RequestService.post('dissov.save', vm.diss)
        .then (response) ->
            $state.go 'app.disscouncil.list'
            toastr.success 'Тема диссертации создана'
        return

    getUsers =  ->
        RequestService.post('user.listing',{}).then (result) ->
            vm.users = result.users
            return
        return



    removeUser = (index) ->
        vm.diss_users.splice index, 1
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
                removeUser(education)
            return
        )
        return

    putDataDegree = ->
        vm.degree = null
        vm.degrees = []
        if vm.degree_academicdegree == null or vm.degree_academicdegree == ' ' or vm.degree_academicdegree == undefined  or vm.degree_academicdegree == []
            toastr.warning('Специальность не выбрана!')
        else
            vm.degree =
                academicdegree:
                    name: vm.degree_academicdegree.name_ru
                    academicdegree_id: vm.degree_academicdegree._id
                branchesofscience: vm.degree_branchesofsciences
                specialty: vm.degree_specialities
            vm.degrees.push vm.degree
            console.log(vm.degrees)
            vm.degree_academicdegree = null
            vm.degree_branchesofscience = null
            vm.degree_specialty = null
            vm.degree = null
            vm.degree_branchesofsciences = []
            vm.degree_specialities = []
        return


    removeDegree = (index) ->
        vm.degrees.splice index, 1


    confirmActionDegree = (index)->
        editModal = $uibModal.open
            templateUrl: 'app/modals/confirmation-dialog.html'
            controller: 'ProfileDialogController'
            controllerAs: 'profile_dialog'
            size: 'sm'
            resolve:
                text: {text: ", что хотите удалить"}
        editModal.result.then((result)->
            if result
                removeDegree(index)
            return
        )
        return

    goBack = ->
        $state.go 'app.disscouncil.list'
        return

    addUser = ->
        vm.dis =
            user:
                first_name: vm.user_person.first_name
                last_name: vm.user_person.last_name
                middle_name: vm.user_person.middle_name
                birthday: vm.user_person.birthday
            user_id: vm.user_person.id
            abstract: vm.refspecialties
            work: vm.workspecialties
            role:  vm.role
        vm.diss_users.push vm.dis
        console.log "diss", vm.diss_users
        vm.user_person = null
        vm.workspecialty = null
        vm.refspecialty = null
        vm.refspecialties = []
        vm.workspecialties = []
        return

    editUser = (index) ->
        disUser = vm.diss_users[index]
        console.log disUser
        if disUser.user == null or disUser.user == undefined or disUser.user == []
            vm.user_person =  ''
        else
            vm.user_person = id: disUser.user_id

        if disUser.abstract == null or disUser.abstract == undefined or disUser.abstract == []
            vm.abstract =  ''
        else
            vm.refspecialties = disUser.abstract
        if disUser.abstract == null or disUser.abstract == undefined or disUser.abstract == []
            vm.abstract  = ''
        else
            vm.workspecialties = disUser.abstract
        if disUser.role == null or disUser.role == undefined
            vm.role  = ''
        else
            vm.role = disUser.role
        removeUser(index)
        return

    vm.refspecialty = null
    addRefspecialty = ->
        if vm.refspecialties is null || vm.refspecialties is undefined
            vm.refspecialties = []
        else
            if vm.refspecialties.includes(vm.refspecialty)
                toastr.warning("This element is already in list ! ! !")
                return

        if vm.refspecialty isnt null and vm.refspecialty isnt undefined and vm.refspecialty isnt ''
            vm.refspecialties.push({
                code: vm.refspecialty.code
                specialty_id: vm.refspecialty._id
            })
            console.log vm.refspecialties["0"]
            vm.refspecialty = null
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deleteRefspecialty = (index) ->
        vm.refspecialties.splice(index,1)
        return

    vm.workspecialty = null
    addWorkspecialty = ->
        if vm.workspecialties is null || vm.workspecialties is undefined
            vm.workspecialties = []
        else
            if vm.workspecialties.includes(vm.workspecialty)
                toastr.warning("This element is already in list ! ! !")
                return

        if vm.workspecialty isnt null and vm.workspecialty isnt undefined and vm.workspecialty isnt ''
            vm.workspecialties.push({
                code: vm.workspecialty.code
                specialty_id: vm.workspecialty._id
            })
            vm.workspecialty = null
        else
            toastr.warning("Нельзя добавлять пустое")
        return

    deleteWorkspecialty = (index) ->
        vm.workspecialties.splice(index,1)
        return


    vm.addWorkspecialty = addWorkspecialty
    vm.deleteWorkspecialty = deleteWorkspecialty
    vm.addRefspecialty = addRefspecialty
    vm.deleteRefspecialty = deleteRefspecialty
    vm.goBack = goBack
    vm.recalculateOnEventAll = recalculateOnEventAll
    vm.addDegreeSpeciality = addDegreeSpeciality
    vm.deleteDegreeSpeciality = deleteDegreeSpeciality
    vm.addDegreeBranchesofscience =addDegreeBranchesofscience
    vm.deleteDegreeBranchesofscience = deleteDegreeBranchesofscience
    vm.addPhone = addPhone
    vm.deletePhone = deletePhone

    vm.addWebsite = addWebsite
    vm.deleteWebsite = deleteWebsite

    vm.addEmail = addEmail
    vm.deleteEmail = deleteEmail

    vm.addAddress = addAddress
    vm.deleteAddress = deleteAddress
    vm.editUser = editUser
    vm.saveDissov = saveDissov
    vm.getUsers = getUsers
    vm.addUser = addUser
    vm.removeUser = removeUser
    vm.confirmAction = confirmAction
    vm.putDataDegree = putDataDegree
    vm.editDegree = editDegree
    vm.removeDegree = removeDegree
    vm.confirmActionDegree = confirmActionDegree
    vm.addOrganization = addOrganization
    vm.deleteOrganization = deleteOrganization

    getUsers()
    return
