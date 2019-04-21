angular.module 'stock'
.directive 'companySelect', ->
    restrict: 'E'
    replace: true
    scope:
        companyId: '='
        asText: '='
        ngDisabled: '=?'
    controller: ($scope, RequestService, $uibModal, $uibModalStack) ->
        'ngInject'
        vm = this
        vm.openSelectCompany = ->
            editModal = $uibModal.open
                templateUrl: 'app/templates/company-select.html'
                controller: 'CompanySelectController'
                controllerAs: 'company'
                scope: $scope.$parent

            editModal.result.then (result)->
                vm.selected = result
                return
            return

        vm.searchCompany = (search_name)->
            RequestService.post 'company.listing', {limit: 10, search:search_name}
            .then (result)->
                result.docs

        $scope.$watch 'companyId', ->
            if (angular.isDefined $scope.companyId) && vm.watch_prevent != true
                RequestService.post 'company.listing', {filter:_id:$scope.companyId}
                .then (result)->
                    if result.docs.length == 1
                        vm.watch_prevent = true
                        vm.selected = result.docs[0]
                    return
            return
        $scope.$watch 'company.selected', ->
            if (angular.isDefined vm.selected) && vm.watch_prevent != true
                vm.watch_prevent = true
                $scope.companyId = vm.selected._id
            vm.watch_prevent = false
            return

        return
    controllerAs: 'company'
    link: (scope, element, attr)->
        return
    template: '<div><div ng-hide="asText===true" class="input-group">
<div class="input-group-addon" ng-show="loadingCompanies">
<span class="glyphicon glyphicon-refresh"></span>
</div>
<div class="input-group-addon" ng-show="noCompanies">
<span class="glyphicon glyphicon-remove text-danger"></span>
</div>
<input type="text" ng-model="company.selected" class="form-control" uib-typeahead="company as company.name for company in company.searchCompany($viewValue)" typeahead-loading="loadingCompanies" typeahead-no-results="noCompanies" ng-disabled="ngDisabled">
<div class="input-group-btn">
<button class="btn btn-primary" type="button" ng-click="company.openSelectCompany()" ng-disabled="ngDisabled">
<span class="glyphicon glyphicon-paperclip"></span>
</button>
</div>
</div>
<span ng-show="asText===true">{{ company.selected.name }}</span></div>'
