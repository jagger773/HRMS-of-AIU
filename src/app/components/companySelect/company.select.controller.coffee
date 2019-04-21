angular.module 'stock'
.controller 'CompanySelectController', ($scope, RequestService, $uibModalInstance) ->
    'ngInject'
    vm = this

    vm.page = 1
    vm.limit = 3

    searchCompanies = (paging)->
        vm.loading = true
        if !paging || angular.isUndefined paging
            vm.page = 1
        filter =
            offset: (vm.page - 1) * vm.limit
            limit: vm.limit
            with_related: true
            search: vm.search_name
        RequestService.post 'company.listing', filter
        .then (result)->
            delete vm.selected_company
            vm.companies = result.docs
            vm.totalItems = result.count
            vm.pages = []
            for i in [1..Math.ceil(vm.totalItems/vm.limit)]
                vm.pages.push i
            vm.loading = false
            return
        , ->
            vm.loading = false
        return

    cancel = ->
        $uibModalInstance.dismiss 'cancel'
        return

    selectCompany = ->
        if angular.isDefined vm.selected_company
            $uibModalInstance.close vm.selected_company
        return

    previousPage = ->
        if vm.page > 1
            vm.page--
        searchCompanies(true)
    toPage = (page)->
        vm.page = page
        searchCompanies(true)
    nextPage = ->
        if vm.page < vm.totalItems / vm.limit
            vm.page++
        searchCompanies(true)

    searchCompanies()

    vm.searchCompanies = searchCompanies
    vm.cancel = cancel
    vm.selectCompany = selectCompany

    vm.previousPage = previousPage
    vm.toPage = toPage
    vm.nextPage = nextPage
    return
