angular.module 'stock'
.controller 'TypeoftrainingController', ($scope, toastr) ->
    'ngInject'
    vm = this
    $scope.edit.preSave = ->
        $scope.edit.dictionary.name = $scope.edit.table.name
        return true
    return
