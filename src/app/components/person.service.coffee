'use strict'
angular.module('stock')
.service 'PersonService', ($http, RequestService) ->
    PersonService = {}

    PersonService.find = (search, limit) ->
        RequestService.post 'person.find',
            search: search
            limit: limit

    PersonService.get = (id) ->
        RequestService.post 'person.find', id: id

    PersonService
