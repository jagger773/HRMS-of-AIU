angular.module 'stock'
.directive 'jsonField', ($filter) ->
    {
        restrict: 'E'
        require: '?ngModel'
        replace: true
        template: [
            '<div class="json-field" style="position:relative;">'
            '  <textarea ng-class="{\'json-error\':parse_error}" style="font-family: Menlo,Monaco,Consolas,\'Courier New\',monospace;" class="form-control" ng-model="json_string"></textarea>'
            '  <button type="button" style="position:absolute;right:20px;top:8px;" ng-click="render()" class="btn btn-xs btn-default">'
            '    <span class="glyphicon glyphicon-indent-left"></span>'
            '  </button>'
            '<style>'
            '.json-field textarea.json-error{border-color:red;}'
            '</style>'
            '</div>'
        ].join('')
        scope: true
        link: (scope, element, attrs, ngModel) ->
            render = () ->
                if ngModel.$viewValue && ngModel.$viewValue != ''
                    try
                        scope.json_string = $filter('json')(ngModel.$viewValue, true)
                        scope.parse_error = false
                    catch
                        scope.parse_error = true
                else
                    scope.parse_error = false
                    scope.json_string = undefined

            scope.render = render
            ngModel.$render = render

            read = () ->
                if scope.json_string && scope.json_string != ''
                    try
                        ngModel.$setViewValue JSON.parse scope.json_string
                        scope.parse_error = false
                    catch
                        scope.parse_error = true
                else
                    scope.parse_error = false
                    ngModel.$setViewValue undefined
                return

            element.on 'blur keyup change', () ->
                scope.$evalAsync read
            read()
            element.find('textarea').on 'keydown', (e) ->
                keyCode = e.keyCode or e.which
                if keyCode == 9
                    e.preventDefault()
                    start = $(this).get(0).selectionStart
                    end = $(this).get(0).selectionEnd
                    $(this).val $(this).val().substring(0, start) + '  ' + $(this).val().substring(end)
                    $(this).get(0).selectionStart = $(this).get(0).selectionEnd = start + 2
                return
    }
