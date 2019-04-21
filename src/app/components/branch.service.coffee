'use strict'
angular.module('stock')
.service 'BranchService', ($http, RequestService) ->
    BranchService = {}

    BranchService.find = (search, limit) ->
        RequestService.post 'branch.find',
            search: search
            limit: limit

    BranchService.get = (id) ->
        RequestService.post 'branch.find', id: id

    BranchService
