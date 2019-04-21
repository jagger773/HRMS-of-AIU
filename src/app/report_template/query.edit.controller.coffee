angular.module 'stock'
.controller 'ReportQueryEditController', ($scope, RequestService, $uibModalInstance, report_query, toastr) ->
    vm = this
    vm.query = report_query || {query: '', params:[]}
    vm.query_params = []

    save = ->
        if vm.saving
            return
        vm.saving = true
        if !vm.query.code
            toastr.warning 'Укажите код'
            vm.saving = false
            return
        if !vm.query.name
            toastr.warning 'Укажите наименование'
            vm.saving = false
            return
        if !vm.query.result_key
            toastr.warning 'Укажите ключ возврата'
            vm.saving = false
            return
        if !vm.query.query
            toastr.warning 'Заполните запрос'
            vm.saving = false
            return
        RequestService.post 'report.query_put', vm.query
        .then (data) ->
            vm.saving = false
            $uibModalInstance.close data
        , ->
            vm.saving = false

    buildParams = ->
        if vm.query.query && vm.query.query != ''
            params_r = /:([\w_]+)(?=\s|;)/g
            params = []
            while match = params_r.exec vm.query.query
                console.log(match)
                if -1 == params.indexOf match[1]
                    params.push {
                        name: match[1]
                    }
            query_params = []
            for param in params
                found = false
                for q_param in vm.query.params
                    if param.name == q_param.name
                        query_params.push q_param
                        found = true
                        break
                if !found
                    query_params.push param
            vm.query.params = query_params

    vm.save = save
    vm.buildParams = buildParams
    vm.cancel = ->
        $uibModalInstance.dismiss('cancel')
    return
