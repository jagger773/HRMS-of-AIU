angular.module 'stock'
.service 'ReportPrint', ($q, RequestService) ->
    report = new Stimulsoft.Report.StiReport()
    return {
        print: (report_template_code, report_queries_params) ->
            promise = $q.defer()
            queries_data = {}
            report_template = ""
            RequestService.post 'report.listing', {filter:code:report_template_code}
            .then (data) ->
                if data.report_list and data.report_list.length == 1
                    report_template = data.report_list[0].template
                    RequestService.post 'report.queries', report_queries_params || {}
                    .then (data) ->
                        queries_data = data.data
                        report.load report_template
                        if queries_data
                            report.dictionary.databases.clear()
                            for code of queries_data
                                report.regData(code, code, queries_data[code])
                            report.render()
                            report.print(null, Stimulsoft.Report.Export.StiHtmlExportMode.Table)
                            promise.resolve {ok: true, message: 'Отчет успешно создан'}
                        else
                            promise.reject {ok: false, message: 'Не удалось получить данные для шаблона'}
                        return
                    , (data) ->
                        promise.reject data
                else
                    promise.reject {ok: false, message: 'Шаблон с таким кодом не найден'}
            , (data) ->
                promise.reject data
            return promise.promise
    }
