'use strict'
angular.module('stock')
.service 'OrganizationService', ($http, RequestService) ->
    OrganizationService = {}

    OrganizationService.find = (search, limit) ->
        RequestService.post 'organization.find',
            search: search
            limit: limit

    OrganizationService.get = (id) ->
        RequestService.post 'organization.find', id: id

    OrganizationService
