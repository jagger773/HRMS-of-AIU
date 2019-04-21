'use strict'
angular.module('stock')
.service 'SpecService', ($http, RequestService) ->
    SpecService = {}

    SpecService.find = (search, limit) ->
        RequestService.post 'spec.find',
            search: search
            limit: limit

    SpecService.get = (id) ->
        RequestService.post 'spec.find', id: id

    SpecService
