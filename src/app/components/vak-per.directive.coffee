'use strict'
angular.module('stock')
.directive 'vakPer', ($compile, PersonService) ->
    {
        restrict: 'AEC'
        scope:
            modeldisplay: '=?'
            modelret: '=?'
            clientType: '=?'
            modelobject: '=?'
            ngDisabled: '=?'
            ngRequired: '=?'
        link: (scope) ->
            scope.current = 0
            scope.selected = false

            scope.da = (txt) ->
                scope.ajaxClass = 'loadImage'
                PersonService.find(txt, 10, scope.clientType).then (response) ->
                    scope.TypeAheadData = response.docs
                    scope.ajaxClass = ''
                    return
                return

            scope.handleSelection = (key, val, object) ->
                scope.modelret = key
                scope.modeldisplay = object
                scope.modelobject = object
                scope.current = 0
                scope.selected = true
                return

            scope.isCurrent = (index) ->
                scope.current == index

            scope.setCurrent = (index) ->
                scope.current = index
                return

            scope.$watch 'modelret', (value) ->
                if value
                    PersonService.get(value).then (response) ->
                        if response.docs.length == 0
                            scope.modeldisplay = null
                            scope.modelobject = null
                            return
                        persona = response.docs[0]
                        scope.modeldisplay = persona.last_name + ' ' + persona.first_name + ' ' + persona.middle_name
                        scope.modelobject = persona
                        return
                else
                    scope.modeldisplay = null
                    scope.modelobject = null
                return
            return
        template: '<input type="text" ng-model="modeldisplay" ng-keyup="da(modeldisplay)" placeholder="Введите ФИО соискателя" class="form-control"  ng-keydown="selected=false" ' + 'style="width:100%;" ng-class="ajaxClass" ng-disabled="ngDisabled" ng-required="ngRequired"> ' + '<div class="list-group table-condensed overlap" ng-hide="!modeldisplay.length || selected" style="width:100%"> ' + '<a href="javascript:;" class="list-group-item noTopBottomPad" ng-repeat="item in TypeAheadData|filter:model  track by $index" ' + 'ng-click="handleSelection(item.id,item.last_name,item)" style="cursor:pointer" ' + 'ng-class="{active:isCurrent($index)}" ' + 'ng-mouseenter="setCurrent($index)"> ' + ' {{item.id}} '+ '<i>{{item.last_name}}</i> ' + '<i>{{item.first_name}}</i> ' + '<i>{{item.middle_name}}</i> ' + '</a> ' + '</div> ' + '</input> '
    }

# ---
# generated by js2coffee 2.2.0