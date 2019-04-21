angular.module 'stock'
.controller 'ReportController', ($scope, RequestService) ->
    vm = this
    viewer = null
    Stimulsoft.Base.Localization.StiLocalization.setLocalizationFile("/app/stimullib/ru.xml")

    createViewer = ->
        options = new Stimulsoft.Viewer.StiViewerOptions()
        options.height = "100%"
        options.appearance.scrollbarsMode = true
        options.toolbar.showDesignButton = false
        options.toolbar.showFullScreenButton = false
        options.exports.showExportToPdf = true
        options.exports.showExportToExcel2007 = true
        options.exports.ShowExportToWord2007 = false
        options.exports.showExportToHtml = false
        options.exports.showExportToDocument = false

        viewer = new Stimulsoft.Viewer.StiViewer(options, "StiViewer", false)

        viewer.renderHtml("reportViewer")
        return

    setReport = (reportObject, data) ->
        viewer.showProcessIndicator()
        setTimeout () ->
            report = new Stimulsoft.Report.StiReport()
            report.load(reportObject)
            if data
                report.dictionary.databases.clear()
                for code of data
                    report.regData(code, code, data[code])
            viewer.report = report
            return
        ,
            50
        return

    getReportList = ->
        filter =
            with_related: ['report_queries']
            filter: report_category_id: vm.report_category_id
        RequestService.post('report.listing', filter).then (data) ->
            vm.reports = data.report_list
            return
        return

    showReport = (report) ->
        reportObject = JSON.parse(report.template) || {}
        setReport(reportObject)

    dictionaryHTML = (rq_param) ->
        html = [
            "<ui-select ng-model='report.template_params[rq.code].#{rq_param.name}'>"
            "<ui-select-match allow-clear='true'>{{$select.selected.#{rq_param.dictionary_show_param}}}</ui-select-match>"
            "<ui-select-choices repeat='item.#{rq_param.dictionary_bind_param} as item in report.dict[rq_param.name]'>{{item.#{rq_param.dictionary_show_param}}}</ui-select-choices>"
            "</ui-select>"
        ].join('')
        return html

    directiveHTML = (rq_param) ->
        html = [
            "<#{rq_param.directive_element}"
            " #{rq_param.directive_bind_attribute}='report.template_params[rq.code].#{rq_param.name}'"
            " "
            "></#{rq_param.directive_element}>"
        ].join('')
        return html

    defaultHTML = (rq_param) ->
        html = [
            "<input type='#{rq_param.param_type}' ng-model='report.template_params[rq.code].#{rq_param.name}'"
            " class='form-control'"
            "/>"
        ].join('')
        return html

    getReportData = ->
        return if vm.data_loading
        vm.data_loading = true
        RequestService.post "report/queries", vm.template_params
        .then (data) ->
            console.log data
            setReport(vm.selected_report.template, data.data)
            vm.data_loading = false
        , ->
            vm.data_loading = false
        return

    $scope.$watch 'report.report_category_id', (newVal, oldVal) ->
        if newVal != oldVal && newVal
            getReportList()

    vm.getReportList = getReportList
    vm.showReport = showReport
    vm.dictionaryHTML = dictionaryHTML
    vm.directiveHTML = directiveHTML
    vm.defaultHTML = defaultHTML
    vm.getReportData = getReportData

    createViewer()
    setReport({})
    document.getElementById("StiViewerReportPanel").style.cssText = "text-align: center;bottom: 0px;position: static;top: 35px;overflow: auto;margin-top: 0px;"
    return
