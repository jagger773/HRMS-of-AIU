angular.module 'stock'
.directive 'input', ()->
    link = (scope, element, attr, ngModel)->
        if attr.type != 'file' || !ngModel
            return
        element.on 'change', ()->
            file = element[0].files[0]
            reader = new FileReader()
            reader.onload = (e)->
                data = e.target.result
                ngModel.$setViewValue data
            reader.readAsBinaryString(file)
            return
        return
    {
        restrict: 'E'
        link: link
        require: '?ngModel'
    }
