module = angular.module('filer.controllers', ['restangular'])

class FileDetailCtrl
        constructor: (@$scope, @Restangular) ->
                console.debug("started file detail")

class FileListCtrl
        constructor: (@$rootScope, @$scope, $timeout, $fileUploader, @Restangular) ->
                @$scope.files = []
                # FIXME: get current bucket from session
                @$scope.currentBucket = 1 
                @$scope.selectedTags = []
                @$scope.search_form =
                        query: ""
                
                @Restangular.one('bucket', @$scope.currentBucket).get().then((bucket) =>
                        @$scope.files = bucket.files
                )
                # FIXME: facet parameters should be added dynamically
                @$scope.autocompleteUrl = "http://localhost:8000/bucket/api/v0/bucketfile/bucket/"+@$scope.currentBucket+"/search?auto="
                @$scope.uploader = $fileUploader.create(
                        scope: @$rootScope
                        autoUpload: true
                        url: 'http://localhost:8000/bucket/upload/'
                        formData: [{bucket: 1}] # FIXME
                )
                
                @$scope.searchFiles = this.searchFiles
                @$scope.removeTag = this.removeTag
                
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
                
                # watch the selection of a tag and add them
                @$scope.$watch('search_form.query', (newValue, oldValue) =>
                        if @$scope.search_form.query
                                tag = @$scope.search_form.query.title
                                if @$scope.selectedTags.indexOf(tag) == -1    
                                        @$scope.selectedTags.push(tag)
                        angular.element('#searchField_value').val("")
                        @$scope.search_form =
                                query : ""
                        # refresh search
                        this.searchFiles()                        
                )

        removeTag: (tag)=>
                index = @$scope.selectedTags.indexOf(tag)
                @$scope.selectedTags.splice(index,1)
                console.debug(" New sel tags == "+@$scope.selectedTags)
                # refresh search
                this.searchFiles()
        
        searchFiles: =>
                console.debug("searching with: ")
                query = angular.element('#searchField_value').val()
                console.debug(query)
                #search URL : http://localhost:8000/bucket/api/v0/bucketfile/bucket/1/search?format=json&q=blabla
                searchFilesObject = @Restangular.one('bucketfile').one('bucket', @$scope.currentBucket)
                
                searchFilesObject.getList('search', {q: query, facet:@$scope.selectedTags }).then((result) =>
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
