angular.module 'stock'
.controller 'AuthController', (RequestService, $scope, toastr, EVENTS, Session, browser, email_mask, AppStorage, $state, $stateParams, vcRecaptchaService) ->
    'ngInject'
    vm = this
    vm.os = browser() ? 'unknown'
    vm.publicKey = "6Lfwh2cUAAAAABzNK0QV1nv-HBInA5mtV2s2SMZD"

    register = () ->
        if(vcRecaptchaService.getResponse() == '')
            toastr.warning 'Пожалуйста решите captcha'
        else
            if not vm.email.match(email_mask)
                toastr.warning 'Укажите валидный email'
                return false
            if vm.auth_loading == true
                return
            vm.auth_loading = true
            vm['g-recaptcha-response'] = vcRecaptchaService.getResponse()
            RequestService.post('user/register', vm)
            .then (data) ->
                Session.create(data.token, data.user)
                $state.go 'confirm'
                vm.auth_loading = false
                return
            , (result)->
                vm.auth_loading = false
                toast result
                return
        return false

    login = () ->
        if vm.auth_loading == true
            return
        vm.auth_loading = true
        RequestService.post('user/auth', vm)
        .then (data) ->
            Session.create(data.token, data.user, data.uc)
            $scope.$emit(EVENTS.loginSuccess)
            vm.auth_loading = false
            return
        , (result)->
            vm.auth_loading = false
            toast if result then result else result:-1,message: 'Ошибка сети'
            return
        return false

    toast = (result)->
        if result.result > 0
            toastr.warning result.message
        else if result.result < 0
            toastr.error result.message

    $scope.$on EVENTS.loginSuccess, ->
        AppStorage.clear()

        ua = Session.getUser()
        $state.go 'app.dashboard'
        return

    vm.register = register
    vm.login = login
    return
