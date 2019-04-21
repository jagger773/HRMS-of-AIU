angular.module 'stock'
.controller 'PositionsController', ($scope, toastr) ->
    'ngInject'
    vm = this
    $scope.edit.preSave = ->
        $scope.edit.dictionary.name = $scope.edit.table.name
        return true
    return
