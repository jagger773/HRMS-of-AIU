angular.module 'stock'
.directive 'uiLevelSelect', ->
    {
        restrict: 'A'
        require: 'uiSelect'
        link: (scope, element, attrs, $select)->
            scope.$watch ->
                return $select.items
            , ->
                $select.activeIndex = if $select.selected then $select.items.indexOf $select.selected else 0
            scope.$watch ->
                return $select.selected
            , ->
                $select.activeIndex = if $select.selected then $select.items.indexOf $select.selected else 0
            return
    }
.directive 'branchSelect', ->
    {
        restrict: 'EA'
        require: ['branchSelect', 'ngModel']
        templateUrl: (element, attrs)->
            if angular.isDefined attrs.multiple then 'app/templates/branch-multiple-select.html' else 'app/templates/branch-select.html'
        scope:
            branches: '='
            multiple: '@'
            placeholder: '@'
        link: (scope, element, attrs, ctrls)->
            $branch = ctrls[0]
            $ngModel = ctrls[1]
            $branch.ngModel = $ngModel
            $ngModel.$render = ->
                if $branch.multiple then $branch.branches_id = $ngModel.$viewValue else $branch.branch_id = $ngModel.$viewValue
            attrs.$observe 'disabled', ->
                $branch.disabled = if !angular.isUndefined attrs.disabled then attrs.disabled else false
            attrs.$observe 'multiple', ->
                $branch.multiple = if !angular.isUndefined attrs.multiple then true else false
            return
        controller: ($scope)->
            vm = this
            vm.parents = []
            vm.ordered_branches = []
            $scope.$watch 'branch.branches_id', (newVal, oldVal)->
                vm.ngModel.$setViewValue newVal if vm.multiple
            $scope.$watch 'branch.branch_id', (newVal, oldVal)->
                vm.ngModel.$setViewValue newVal if !vm.multiple
                if angular.isDefined(newVal) && angular.isDefined($scope.branches)
                    (branch = item) for item in $scope.branches when item._id == newVal
                    if branch && vm.parents.indexOf(branch._id) == -1 && vm.parents.indexOf(branch.parent_id) == -1
                        toggleParent(branch)
            $scope.$watch 'branches', ->
                if vm.multiple && angular.isDefined $scope.branches
                    reorderBranches()
                    return
                if angular.isDefined(vm.branch_id) && angular.isDefined $scope.branches
                    (branch = item) for item in $scope.branches when item._id == vm.branch_id
                    toggleParent(branch)
            group = (branch)->
                return if isParent(branch)
                return ' '
            groupFilter = (group)->
                return group
            isVisible = (branch)->
                if vm.parents.length == 0
                    return branch.parent_id == null || angular.isUndefined branch.parent_id
                return vm.parents[vm.parents.length-1] == branch.parent_id || isParent(branch)
            isParent = (branch)->
                -1 < vm.parents.indexOf branch._id
            hasChild = (branch)->
                (item for item in $scope.branches when item.parent_id == branch._id).length > 0
            toggleParent = (branch)->
                if angular.isUndefined(branch) || angular.isUndefined branch._id
                    vm.parents = []
                    return
                index = vm.parents.indexOf(branch._id)
                if index > -1
                    vm.parents.splice(index, vm.parents.length - index)
                else if hasChild(branch)
                    if branch.parent_id == null || angular.isUndefined branch.parent_id
                        vm.parents = [branch._id]
                    else if vm.parents.length > 0 && vm.parents[vm.parents.length-1] == branch.parent_id
                        vm.parents.push branch._id
                    else if vm.parents.length == 0
                        (parent = item) for item in $scope.branches when item._id == branch.parent_id
                        toggleParent(parent)
                        vm.parents.push branch._id
                    else if vm.parents.length > 0 && vm.parents[vm.parents.length-1] != branch.parent_id
                        vm.parents = []
                        (parent = item) for item in $scope.branches when item._id == branch.parent_id
                        toggleParent(parent)
                        vm.parents.push branch._id
            parentCount = (branch)->
                parent_count = 0
                if branch.parent_id != null && angular.isDefined branch.parent_id
                    parent_count = 1
                    (parent = item) for item in $scope.branches when item._id == branch.parent_id
                    parent_count += parentCount(parent)
                return parent_count

            reorderBranches = ->
                reorder = angular.copy $scope.branches

                findParent = (p_id)->
                    return if p_id == null || angular.isUndefined p_id
                    return item for item in reorder when item._id == p_id

                findChildren = (id)->
                    result = []
                    items = (item for item in reorder when item.parent_id == id)
                    for item in items
                        children = findChildren item._id
                        result.push item
                        result = result.concat children
                    return result

                ordered = []
                no_parents = []
                for item in reorder
                    no_parents.push item if !findParent item.parent_id
                for item in no_parents
                    children = findChildren item._id
                    ordered.push item
                    ordered = ordered.concat children
                vm.ordered_branches = ordered

            vm.group = group
            vm.groupFilter = groupFilter
            vm.isVisible = isVisible
            vm.hasChild = hasChild
            vm.toggleParent = toggleParent
            vm.parentCount = parentCount
            return
        controllerAs: 'branch'
    }
