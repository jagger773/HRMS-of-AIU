angular.module 'stock'
.directive 'documentComment', ->
    scope:
        documentId: '='
    templateUrl: 'app/docs/comments.html'
    controller: 'CommentsController'
    controllerAs: 'comments'