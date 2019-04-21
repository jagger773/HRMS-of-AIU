angular.module 'stock'
.config ($logProvider, toastrConfig, hotkeysProvider, $httpProvider, uibDatepickerPopupConfig) ->
    'ngInject'
    # Enable log
    $logProvider.debugEnabled true
    # Set options third-party lib
    toastrConfig.allowHtml = true
    toastrConfig.timeOut = 3000
    toastrConfig.positionClass = 'toast-top-right'
    toastrConfig.preventOpenDuplicates = true
    toastrConfig.progressBar = true
    hotkeysProvider.cheatSheetHotkey = ["h", "р"]
    hotkeysProvider.cheatSheetDescription = "Информация о быстрых кнопках открыть/закрыть"
    $httpProvider.interceptors.push('authInterceptor')
    uibDatepickerPopupConfig.datepickerPopup = 'dd-MM-yyyy'
    uibDatepickerPopupConfig.clearText = 'Очистить'
    uibDatepickerPopupConfig.closeText = 'Закрыть'
    uibDatepickerPopupConfig.currentText = 'Сегодня'
    uibDatepickerPopupConfig.altInputFormats = ['yyyy-MM-dd HH:mm:ssZ']
.config ($translateProvider) ->
    'ngInject'
    $translateProvider.useStaticFilesLoader({
        files: [{
            prefix: 'assets/i18n/locale-',
            suffix: '.json'
        }]
    })
    $translateProvider.preferredLanguage('ru')
    $translateProvider.useSanitizeValueStrategy('escape')

