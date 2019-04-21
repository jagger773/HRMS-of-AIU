'use strict'
angular.module('stock')
.service 'SpecrankService', ($http, RequestService) ->
    SpecrankService = {}

    SpecrankService.find = (search, limit) ->
        RequestService.post 'specrank.find',
            search: search
            limit: limit

    SpecrankService.get = (id) ->
        RequestService.post 'specrank.find', id: id

    SpecrankService
