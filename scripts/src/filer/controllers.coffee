module = angular.module('filer.controllers', ['restangular', 'angular-unisson-auth'])

class LoginCtrl
        constructor: (@$scope, @loginService) ->
                @$scope.loginService = @loginService

class ToolbarCtrl
        constructor: (@$scope, @filerService) ->
                @$scope.panel = null
                @$scope.filerService = @filerService

class FileDetailCtrl
        constructor: (@$scope, @filerService, @Restangular, @$stateParams, @$state, $timeout, $window) ->
                console.debug("started file detail on file:"+ @$stateParams.fileId)
                @$scope.tab = 1
                # == CReate preview layout ==  FIXME (so ugly!!)
                $timeout(()-> 
                        container = angular.element('#cards-wrapper')
                        container.isotope('destroy')
                        # 1. change class of drive-app div
                        angular.element("#drive-app").addClass("preview-mode")
                        console.log("AVANT RUN ISOTOPE ")
                        # fetch the index of the current element
                        listItemPreviewed = angular.element('.previewed').parent('.element')
                        index = angular.element('.element').index(listItemPreviewed)
                        # get the width of the container, here we are talking about cards-wrapper
                        containerWidth = angular.element('#cards-wrapper').width()
                        # get the number of cards per line we can have
                        cardsNumberPerLine = parseInt(containerWidth / 252);
                        # get the line of the current element
                        currentLine = parseInt(index / cardsNumberPerLine);
                        # get the element after which we will have to inject the preview panel
                        lastElement = currentLine * cardsNumberPerLine + cardsNumberPerLine
                        cardsNumberTotal = angular.element('.element').length
                        if lastElement > cardsNumberTotal
                                lastElement = cardsNumberTotal
                        # move the preview panel in the right place
                        angular.element('#preview-panel-wrapper').insertAfter(angular.element('.element').eq(lastElement - 1))
                ,300
                )
                # FIXME ? we build a dummy and temporary file object here that can be immediately used 
                # by child controllers (as FileCommentCtrl) before the promisse is realized
                @$scope.file = 
                        id: @$stateParams.fileId
                @$scope.fileRestObject = @Restangular.one('bucketfile', @$scope.file.id) 
                @$scope.fileRestObject.get().then((result)=>
                        @$scope.file = result
                )
                
                # Method
                @$scope.exit = ()=>
                        angular.element("#drive-app").removeClass("preview-mode")
                        @$state.transitionTo('bucket')
                        $timeout(()->
                                $scope.runIsotope()
                        ,1000
                        )
                        return true
                        
                @$scope.addLabels = (fileId)=>
                        params =
                                filesIds: fileId
                        @$state.transitionTo('bucket.labellisation',params)
                
                @$scope.openFile = ()=>
                        $window.open(config.bucket_preview_uri + @$scope.file.file)
                
                 @$scope.openForEdition = (fileId)=>
                        console.log("opening file "+fileId+" for edition")
                        # patch file with object {"being_edited_by": {"pk": "9"}}
                        @$scope.fileRestObject.patch({"being_edited_by": {"pk": @$scope.authVars.profile_id}}).then((result)=>
                                console.debug(" file is now being updated " )
                                @$scope.openFile()
                        )
                        
                        
class FileLabellisationCtrl
# designed for multifiles, but multifile selection is still missing
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
                
                # Populating suggested (most used) tags
                @$scope.suggestedTags = []
                @$scope.tagsList = @Restangular.one('bucketfile').one('bucket', @$scope.currentBucket)
                @$scope.tagsList.getList('search',{ auto: ""}).then((result) =>
                         @$scope.suggestedTags = result.slice(0,10)
                )
                console.log(" suggested tags ")
                console.log(@$scope.suggestedTags)
                
                # Watch selection of existing tag and add to suggested tags 
                @$scope.tagAutocompleteUrl = config.rest_uri+"/bucketfile/bucket/"+@$scope.currentBucket+"/search?auto="
                @$scope.tag_search_form =
                        query: ""
                @$scope.$watch('tag_search_form.query', (newValue, oldValue) =>
                        console.debug("== Tag selected (labellisation)!")
                        if @$scope.tag_search_form.query
                                tag = 
                                        name: @$scope.tag_search_form.query.title
                                # FIXME: according to Hervé's design, here we only add tag to suggested tags queue, 
                                # but I think it'll be quicker to add them directly to all files (bulk tagging)
                                if @$scope.suggestedTags.indexOf(tag) == -1
                                        @$scope.suggestedTags.push(tag)
                                if @$scope.taggingQueue[@$scope.files[0].id].indexOf(tag) == -1
                                        @$scope.taggingQueue[@$scope.files[0].id].push(tag)
                        # empty search box 
                        angular.element('#tagSearchField_value').val("")
                        @$scope.tag_search_form =
                                query : ""
                )
                
                # Methods  
                @$scope.addToSuggestedTags = this.addToSuggestedTags
                @$scope.addTag = this.addTag 
                @$scope.removeTag = this.removeTag    
                @$scope.updateTags = this.updateTags
                @$scope.goHome = ()=>
                        @$state.transitionTo('bucket',{},{reload:true})
                @$scope.goToFile = (id)=>
                        params=
                                fileId: id
                        @$state.transitionTo('bucket/file', params)
        
        addToSuggestedTags: =>
                console.log("add t suggested tags")
                tagString = angular.element('#tagSearchField_value').val()
                console.debug(tagString)
                tag = 
                        name: tagString
                angular.element('#tagSearchField_value').val("")
                if @$scope.suggestedTags.indexOf(tag) == -1
                        @$scope.suggestedTags.push(tag)
                if @$scope.taggingQueue[@$scope.files[0].id].indexOf(tag) == -1
                        @$scope.taggingQueue[@$scope.files[0].id].push(tag)
                
        
        addTag: (fileId, tag)=>
                console.log( "++ adding tag : " + tag.name + " to file :" +fileId)
                file = @$filter('filter')(@$scope.files, {id : fileId})[0]
                if @$scope.taggingQueue[fileId].indexOf(tag) == -1
                        @$scope.taggingQueue[fileId].push(tag)
                console.log("+new tagging queue+")
                console.log(@$scope.taggingQueue)
        
        removeTag: (fileId, tag)=>
                console.log( "++ removing tag : " + tag.name + " from file :" +fileId)
                index = @$scope.taggingQueue[fileId].indexOf(tag)
                @$scope.taggingQueue[fileId].splice(index, 1)
                console.log("+new tagging queue+")
                console.log(@$scope.taggingQueue)
                
        updateTags: =>
                console.log("updating tags")
                # loop in tagging queue, and do a PATCH
                for fileId, tags of @$scope.taggingQueue
                        do (fileId, tags)=>
                                console.log("tags for file: "+fileId)
                                tagsObject = 
                                        tags:tags
                                console.log(tagsObject)
                                fileRestObject = @Restangular.one('bucketfile', fileId)                
                                fileRestObject.patch(tagsObject).then(()=>
                                        console.debug(" tags updated ! " )
                                        )
                @$scope.goHome()
                
                
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
                # AUTOCOMPLETE SETUP
                # FIXME : get root URL from config file
                @$scope.autocompleteUrl = config.rest_uri+"/bucketfile/bucket/"+@$scope.currentBucket+"/search?auto="
                # needed to avoid default browser's autocomplete
                $timeout(()->
                        angular.element("#searchField_value").attr("autocomplete", "off")
                ,1000
                )
                # Methods declaration
                @$scope.updateAutocompleteURL = this.updateAutocompleteURL
                @$scope.searchFiles = this.searchFiles
                @$scope.removeTag = this.removeTag

                # Quick hack so isotope renders when file changes
                @$scope.$watch('files', ->
                        $timeout(()->
                                console.log(" === runIsotope wthon FileLIst after timeout") 
                                $scope.runIsotope()
                        ,2500
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
                @$scope.autocompleteUrl = config.rest_uri+"/bucketfile/bucket/"+@$scope.currentBucket+"/search?"+facetQuery+"&auto="                        

        
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
                #search URL : config.rest_uri+ /bucketfile/bucket/1/search?format=json&q=blabla
                @$scope.searchFilesObject.getList('search', {q: query, facet:@$scope.selectedTags }).then((result) =>
                         @$scope.files = result
                )

class FileCommentCtrl
# child controller of either FileDetail or FileList, hence the dependency on @$scope.file
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
                                console.debug(@$scope.comments)
                                @$scope.comment_form.text=""
                                @$scope.comments.push(addedComment)
                                )

module.controller("LoginCtrl", ['$scope','loginService', LoginCtrl])
module.controller("ToolbarCtrl", ['$scope', 'filerService', ToolbarCtrl])
module.controller("FileDetailCtrl", ['$scope', 'filerService', 'Restangular', '$stateParams','$state', '$timeout', '$window', FileDetailCtrl])
module.controller("FileLabellisationCtrl", ['$scope', 'Restangular', '$stateParams','$state', '$filter', FileLabellisationCtrl])
module.controller("FileListCtrl", ['$scope', 'filerService', '$timeout', 'Restangular', FileListCtrl])
module.controller("FileCommentCtrl", ['$scope', 'Restangular', FileCommentCtrl])
