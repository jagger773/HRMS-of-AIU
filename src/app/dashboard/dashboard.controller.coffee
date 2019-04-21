angular.module 'stock'
.controller 'DashboardController', ($scope, RequestService)->
    'ngInject'
    vm = this

    vm.filter =
        start_date: moment().startOf('isoWeek').toDate()
        end_date: moment().endOf('day').toDate()


    return
