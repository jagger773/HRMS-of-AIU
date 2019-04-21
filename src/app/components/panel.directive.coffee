angular.module 'stock'
.directive 'panel', ()->
    link = (scope, el, attr)->
        scope.is_collapsed = angular.isDefined(attr.collapsed) && scope.$eval(attr.collapsed) == true
        return
    {
        restrict: 'E'
        transclude: true
        scope: {
            title: '@'
            collapsed: '@'
        }
        link: link
        template: '<div class="x_panel">
                    <div class="x_title">
                        <h2 uib-tooltip="{{title}}">{{title}}</h2>
                        <ul class="nav navbar-right panel_toolbox">
                            <li><a class="collapse-link" ng-click="is_collapsed=!is_collapsed"><i class="fa" ng-class="{\'fa-chevron-up\':!is_collapsed,\'fa-chevron-down\':is_collapsed}"></i></a></li>
                            <li><a class=""><i class="fa fa-wrench"></i></a></li>
                            <li><a class="close-link"><i class="fa fa-close"></i></a></li>
                        </ul>
                        <div class="clearfix"></div>
                    </div>
                    <div class="x_content" uib-collapse="is_collapsed" ng-transclude>
                    </div>
                   </div>'
    }
