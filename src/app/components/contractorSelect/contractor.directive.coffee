angular.module 'stock'
.directive 'contractorSelect', ->
    restrict: 'E'
    replace: true
    scope:
        contractorId: '='
        item: '='
        ngDisabled: '=?'
        ngRequired: '=?'
        modalOptions: '=?'
    controller: ($scope, $attrs, RequestService, $uibModal, $uibModalStack) ->
        'ngInject'
        vm = this
        vm.openSelectContractor = ->
            editModal = $uibModal.open
                templateUrl: 'app/components/contractorSelect/select.html'
                controller: 'ContractorSelectController'
                controllerAs: 'contractor'
                size: 'lg'
                scope: $scope.$parent
                resolve:
                    modalOptions: $scope.modalOptions || {}

            editModal.result.then (result)->
                vm.selected = result
                return
            return

        vm.searchContractor = (search_name)->
            filter =
                limit: 10
                search: search_name
                filter: if $scope.modalOptions then $scope.modalOptions.filter
            RequestService.post 'contractor.list', filter
            .then (result)->
                result.docs

        $scope.$watch 'contractorId', ->
            if (angular.isDefined $scope.contractorId) && vm.watch_prevent != true
                RequestService.post 'contractor.list', {filter:_id:$scope.contractorId}
                .then (result)->
                    if result.docs.length == 1
                        vm.watch_prevent = true
                        vm.selected = result.docs[0]
                    return
            return
        $scope.$watch 'contractor.selected', ->
            if (angular.isDefined vm.selected) && vm.watch_prevent != true
                vm.watch_prevent = true
                $scope.contractorId = vm.selected._id
                if $attrs.item
                    $scope.item = vm.selected
            vm.watch_prevent = false
            return

        return
    controllerAs: 'contractor'
    link: (scope, element, attr)->
        return
    templateUrl: 'app/components/contractorSelect/contractor-select.html'
