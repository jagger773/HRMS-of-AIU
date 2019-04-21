angular.module 'stock'
.controller 'SearchProdController', ($scope, $uibModalInstance, uiGridConstants, $timeout)->
    $scope.gridOptions = {
        noUnselect: true
        columnDefs: [
            {name: 'data.name', pinnedLeft: true, displayName: 'Наименование'},
            {name: 'data.price', pinnedLeft: true, displayName: 'Цена'},
        ]
    }
#    search = ()->
#        db.search 'product', $scope.query, ['data.name', 'data.ean'], 20, 0
#        .then (result)->
#            $scope.gridOptions.data = result.docs
#            $scope.gridOptions.gridApi.core.notifyDataChange uiGridConstants.dataChange.ALL
#            if result.docs.length > 0
#                $timeout () ->
#                    $scope.gridOptions.gridApi.selection.selectRow $scope.gridOptions.data[0]
    $scope.ok = ()->
        $uibModalInstance.close($scope.entity)
    $scope.cancel = ()->
        $uibModalInstance.dismiss()
    $scope.pressed = (e)->
        if e.keyCode == 13 and $scope.entity
            $scope.ok()
        return
#    $scope.$watch 'query', search
    $scope.$on 'data-selected', (e, row)->
        $scope.entity = row.entity
    return
