angular.module 'stock'
.controller 'SectionsofpublicationController', ($scope, toastr) ->
    'ngInject'
    vm = this
    $scope.edit.preSave = ->
        $scope.edit.dictionary.name = $scope.edit.table.name
        return true
    return
