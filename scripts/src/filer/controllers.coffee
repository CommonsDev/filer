module = angular.module('filer.controllers', ['restangular'])

class FileDetailCtrl
        constructor: (@$scope, @Restangular) ->
                console.debug("started file detail")

class FileListCtrl
        constructor: (@$rootScope, @$scope, $timeout, $fileUploader, @Restangular) ->
                @$scope.files = []
                @$scope.currentBucket = 1
                @Restangular.one('bucket', @$scope.currentBucket).get().then((bucket) =>
                        @$scope.files = bucket.files
                )

                @$scope.uploader = $fileUploader.create(
                        scope: @$rootScope
                        autoUpload: true
                        url: 'http://localhost:8000/bucket/upload/'
                        formData: [{bucket: 1}] # FIXME
                )

                @$scope.search_form =
                        query: ""
                @$scope.searchFiles = this.searchFiles

                # Quick hack so isotope renders when file changes
                @$scope.$watch('files', ->
                        $timeout(->
                                # Run isotope
                                container = $('#cards-wrapper')
                                container.isotope(
                                  itemSelector: '.element'
                                  layoutMode: 'fitRows'
                                )
                        )
                )


        searchFiles: =>
                console.debug("searching with: #{@$scope.search_form.query}")
                #search URL : http://localhost:8000/bucket/api/v0/bucketfile/bucket/1/search?format=json&q=blabla
                searchFilesObject = @Restangular.one('bucketfile').one('bucket', @$scope.currentBucket)

                searchFilesObject.getList('search', {q: @$scope.search_form.query }).then((result) =>
                         @$scope.files = result
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

module.controller("FileDetailCtrl", ['$scope', 'Restangular', FileDetailCtrl])
module.controller("FileListCtrl", ['$rootScope', '$scope', '$timeout', '$fileUploader', 'Restangular', FileListCtrl])
module.controller("FileCommentCtrl", ['$scope', 'Restangular', FileCommentCtrl])
