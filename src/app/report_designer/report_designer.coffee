angular.module 'stock'
.controller 'Report_designerController', ($scope, RequestService, $stateParams, $document, $state) ->
    designer = null
    vm = this
    vm.id = if $stateParams.id && $stateParams.id != '' then $stateParams.id else null

    Stimulsoft.Base.Localization.StiLocalization.setLocalizationFile("/app/stimullib/ru.xml")

    vm.template = { template: '{ "ReportVersion":"2016.2.5", "ReportGuid":"fa01abce0ca5d18ec4ad5a91c86cf9ed", "ReportName":"Report", "ReportAlias":"Report", "ReportCreated":"/Date(1480997975000+0600)/", "ReportChanged":"/Date(1480997975000+0600)/", "EngineVersion":"EngineV2", "CalculationMode":"Interpretation", "Pages":{ "0":{ "Ident":"StiPage", "Name":"Page1", "Guid":"4c037a5bc82cc89b8aaeaca0d31be61e", "Interaction":{ "Ident":"StiInteraction" }, "Border":";;2;;;;;solid:Black", "Brush":"solid:Transparent", "PageWidth":21.01, "PageHeight":29.69, "Watermark":{ "TextBrush":"solid:50,0,0,0" }, "Margins":{ "Left":1, "Right":1, "Top":1, "Bottom":1 } } } }' }

    vm.report_queries_params = {}

    createDesigner = ->
        options = new Stimulsoft.Designer.StiDesignerOptions()

        options.toolbar.showAboutButton = false
        options.toolbar.showFileMenu = false
        options.toolbar.showFileMenuClose = false
        options.toolbar.showFileMenuExit = false
        options.toolbar.showFileMenuNew = false
        options.toolbar.showFileMenuOpen = false
        options.toolbar.showFileMenuOptions = true
        options.toolbar.showFileMenuReportSetup = true
        options.toolbar.showFileMenuSave = false
        options.toolbar.showFileMenuSaveAs = false
        options.toolbar.showPageButton = true
        options.toolbar.showPreviewButton = true
        options.toolbar.showSaveButton = false

        options.appearance.fullScreenMode = false
        options.appearance.htmlRenderMode = Stimulsoft.Report.Export.StiHtmlExportMode.Table

        designer = new Stimulsoft.Designer.StiDesigner(options, "StiDesigner", false)

        designer.onExit = (e) ->
            e.preventDefault()

        designer.renderHtml("reportDesigner")
        resizeBtn = $document.find '#StiDesignerresizeDesigner'
        resizeBtn[0].action = designerFullWindowToggle

        setReport(vm.template.template)
        return

    setReport = (reportObject, data) ->
        report = new Stimulsoft.Report.StiReport()
        report.load(reportObject)

        if data
            report.dictionary.databases.clear()
            for code of data
                report.regData(code, code, data[code])

        designer.report = report
        return

    getTemplate = ->
        return if vm.loading
        vm.loading = true
        RequestService.post 'report.get', {id: vm.id}
        .then (data) ->
            vm.template = data.report
            if vm.template.report_queries_code
                vm.report_queries_params = {}
                for query_code in vm.template.report_queries_code
                    vm.report_queries_params[query_code] = {}
            createDesigner()
            vm.loading = false
            return
        , ->
            vm.loading = false
            return

    designerFullWindowToggle = ->
        body = $document.find('body')
        reportDesigner = $document.find('#reportDesigner')
        if body.hasClass('report-designer-fullscreen')
            body.removeClass('report-designer-fullscreen')
            reportDesigner.removeClass('fullscreen')
        else
            body.addClass('report-designer-fullscreen')
            reportDesigner.addClass('fullscreen')

    applyQueryCodes = ->
        return if !vm.report_queries_params or vm.loading
        vm.loading = true
        RequestService.post 'report.queries', vm.report_queries_params
        .then (data) ->
            setReport(vm.template.template, data.data)
            vm.loading = false
            return
        , ->
            vm.loading = false

    updateTemplate = ->
        vm.template.template = designer.report.saveToJsonString()
        vm.template.report_queries_code = []
        for code of vm.report_queries_params
            vm.template.report_queries_code.push code
        return

    save = ->
        if vm.saving
            return
        vm.saving = true
        if !vm.template.code
            toastr.warning 'Укажите код'
            vm.saving = false
            return
        if !vm.template.name
            toastr.warning 'Укажите наименование'
            vm.saving = false
            return
        if !vm.template.report_category_id
            toastr.warning 'Укажите категорию'
            vm.saving = false
            return
        if !vm.template.template
            toastr.warning 'Заполните шаблон'
            vm.saving = false
            return
        RequestService.post 'report.put', vm.template
        .then (data) ->
            vm.template._id = data.id
            vm.template._rev = data.rev
            vm.saving = false
            if vm.id == null
                $state.go 'app.report_designer', {id:data.id}
        , ->
            vm.saving = false

    if vm.id
        getTemplate()
    else
        createDesigner()

    vm.applyQueryCodes = applyQueryCodes
    vm.updateTemplate = updateTemplate
    vm.save = save

    return
