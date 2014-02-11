module = angular.module('filer.controllers', ['restangular'])

class FileListCtrl
        constructor: (@$scope, @Restangular) ->
                @$scope.files = []

                @Restangular.one('bucket', 1).get().then((bucket)=>
                        @$scope.files = bucket.files
                        )
                
class FileCommentCtrl
        constructor: (@$scope, @Restangular) ->
                @$scope.comment_form = 
                        text: ""
                @$scope.submitForm = this.submitForm
                @commentsObject = @Restangular.all('bucketfilecomment')
                @$scope.comments = @commentsObject.getList({bucket_file:@$scope.file.id}).$object
                
        submitForm: =>
                console.debug("form soumis avec: "+@$scope.comment_form.text+" file: " +@$scope.file.resource_uri)
                newComment =
                        bucket_file: @$scope.file.resource_uri
                        text: @$scope.comment_form.text
                console.debug(newComment)
                if newComment.text.length > 3
                        @commentsObject.post(newComment).then((addedComment)=>
                                console.debug(" comment saved ! " )
                                @$scope.comment_form.text=""
                                @$scope.comments.push(addedComment)
                                )       
                        
module.controller("FileListCtrl", ['$scope', 'Restangular', FileListCtrl])
module.controller("FileCommentCtrl", ['$scope', 'Restangular', FileCommentCtrl])
