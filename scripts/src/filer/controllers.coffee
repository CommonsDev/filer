module = angular.module('filer.controllers', ['restangular'])

class ToolbarCtrl
        constructor: (@$scope, @filerService) ->
                @$scope.panel = null
                @$scope.filerService = @filerService

class FileDetailCtrl
        constructor: (@$scope, @Restangular, @$stateParams, @$state) ->
                console.debug("started file detail on file:"+ @$stateParams.fileId)
                @$scope.tab = 1
                @$scope.file = 
                        id: @$stateParams.fileId
                
                # http://localhost:8000/bucket/api/v0/bucketfile/1
                @Restangular.one('bucketfile', @$scope.file.id ).get().then((result)=>
                        @$scope.file = result
                        console.debug(@$scope.file)
                )
                # Method
                @$scope.addLabels = (fileId)=>
                        console.log(" == + == adding labels for file : "+fileId)
                        params =
                                filesIds: fileId
                        console.log(params)
                        @$state.transitionTo('bucket.labellisation',params)

class FileLabellisationCtrl
        constructor:  (@$scope, @Restangular, @$stateParams, @$state, @$filter) ->
                console.log(" labellilabello started !!")
                # Populating file if provided as stateParam
                @$scope.files = []
                @$scope.taggingQueue = {}
                if @$stateParams.filesIds
                        @Restangular.one('bucketfile').one("set", @$stateParams.filesIds).getList().then((result) =>
                                @$scope.files = result
                                # Populating tagging queue with current tags if any
                                for file in @$scope.files
                                        do(file)=>
                                                @$scope.taggingQueue[file.id] = file.tags
                        )
                
                # Populating most used tags
                @$scope.suggestedTags = []
                @$scope.tagsList = @Restangular.one('bucketfile').one('bucket', @$scope.currentBucket)
                @$scope.tagsList.getList('search',{ auto: ""}).then((result) =>
                         @$scope.suggestedTags = result
                )
                console.log(" suggested tags ")
                console.log(@$scope.suggestedTags)
                
                # Methods   
                @$scope.addTag = this.addTag     
                @$scope.updateTags = this.updateTags
                @$scope.goHome = ()=>
                        @$state.transitionTo('bucket')
        
        addTag: (fileId, tag)=>
                console.log( "++ adding tag : " + tag.name + " to file :" +fileId)
                file = @$filter('filter')(@$scope.files, {id : fileId})[0]
                console.log(file)
                console.log(@$scope.files)
                @$scope.taggingQueue[fileId].push(tag)
                
        updateTags: =>
                console.log("updating tags")
                
                
class FileListCtrl
        constructor: (@$scope, @filerService, $timeout, @Restangular) ->
                @$scope.files = []
                # FIXME: get current bucket from session
                @$scope.currentBucket = 1
                @$scope.selectedTags = []
                @$scope.search_form =
                        query: ""
                @$scope.searchFilesObject = @Restangular.one('bucketfile').one('bucket', @$scope.currentBucket)
                @$scope.searchFilesObject.getList('search',{}).then((result) =>
                         @$scope.files = result
                )
               
                @$scope.autocompleteUrl = "http://localhost:8000/bucket/api/v0/bucketfile/bucket/"+@$scope.currentBucket+"/search?auto="

                # Methods declaration
                @$scope.updateAutocompleteURL = this.updateAutocompleteURL
                @$scope.searchFiles = this.searchFiles
                @$scope.removeTag = this.removeTag

                # Quick hack so isotope renders when file changes
                @$scope.$watch('files', ->
                        $timeout(->
                                # Run isotope
                                container = angular.element('#cards-wrapper')
                                container.isotope(
                                  itemSelector: 'article'
                                  layoutMode: 'fitRows'
                                )
                        )
                )

                # watch the selection of a tag and add them
                @$scope.$watch('search_form.query', (newValue, oldValue) =>
                        console.debug("== Tag selected !")
                        if @$scope.search_form.query
                                tag = @$scope.search_form.query.title
                                if @$scope.selectedTags.indexOf(tag) == -1
                                        @$scope.selectedTags.push(tag)
                        angular.element('#searchField_value').val("")
                        @$scope.search_form =
                                query : ""
                        # refresh search
                        this.searchFiles()
                        this.updateAutocompleteURL()
                )
        
        updateAutocompleteURL: =>
                # add facet to autocomplete URL$
                facets = ["facet="+facet for facet in @$scope.selectedTags]
                facetQuery = facets.join("&")
                console.debug(facets)
                @$scope.autocompleteUrl = "http://localhost:8000/bucket/api/v0/bucketfile/bucket/"+@$scope.currentBucket+"/search?"+facetQuery+"&auto="                        

        
        removeTag: (tag)=>
                index = @$scope.selectedTags.indexOf(tag)
                @$scope.selectedTags.splice(index,1)
                console.debug(" New sel tags == "+@$scope.selectedTags)
                # refresh search
                this.searchFiles()
                this.updateAutocompleteURL()
        

        searchFiles: =>
                console.debug("searching with: ")
                query = angular.element('#searchField_value').val()
                console.debug(query)
                #search URL : http://localhost:8000/bucket/api/v0/bucketfile/bucket/1/search?format=json&q=blabla
                @$scope.searchFilesObject.getList('search', {q: query, facet:@$scope.selectedTags }).then((result) =>
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

module.controller("ToolbarCtrl", ['$scope', 'filerService', ToolbarCtrl])
module.controller("FileDetailCtrl", ['$scope', 'Restangular', '$stateParams','$state', FileDetailCtrl])
module.controller("FileLabellisationCtrl", ['$scope', 'Restangular', '$stateParams','$state', '$filter', FileLabellisationCtrl])
module.controller("FileListCtrl", ['$scope', 'filerService', '$timeout', 'Restangular', FileListCtrl])
module.controller("FileCommentCtrl", ['$scope', 'Restangular', FileCommentCtrl])
