module = angular.module('filer.controllers', ['restangular', 'angular-unisson-auth'])

class LoginCtrl
        constructor: (@$scope, @loginService) ->
                @$scope.loginService = @loginService

class ToolbarCtrl
        constructor: (@$scope, @filerService) ->
                @$scope.panel = null
                @$scope.filerService = @filerService

class FileDetailCtrl
        constructor: (@$scope, @filerService, @Restangular, @$stateParams, @$state, @$timeout, @$window) ->
                console.debug("started file detail on file:"+ @$stateParams.fileId)
                # FIXME: we build a dummy and temporary file object here that can be immediately used 
                #        by child controllers (as FileCommentCtrl) before the promisse is realized
                @$scope.file = 
                        id: @$stateParams.fileId
                        being_edited_by : {}
                @$scope.fileRestObject = @Restangular.one('bucketfile', @$scope.file.id) 
                @$scope.fileRestObject.get().then((result)=>
                        @$scope.file = result
                )
                
                 #$@scope.isotope_container.isotope('on', 'layoutComplete', @$rootScope.isotopeOnLayout)
                # if files is empty, wait for fileListComplete event
                if @$scope.files.length <= 0
                        @$scope.$on('fileListComplete',  () =>
                                console.log('receive File list complete [FileDetailCtr]')
                                @$timeout(() =>
                                        @$scope.setPreviewLayout() 
                                ,1000
                                )
                        )
                else
                        @$timeout(() => 
                                @$scope.setPreviewLayout()    
                        ,30
                        )
                
                ## Methods ##
                # CReate preview layout FIXME (so ugly!!)
                @$scope.setPreviewLayout = this.setPreviewLayout
                @$scope.exit = this.exit
                @$scope.openForEdition = this.openForEdition
                @$scope.openFile = this.openFile
                @$scope.addLabels = this.addLabels 
                @$scope.cancelOpenForEdition = this.cancelOpenForEdition
                
        setPreviewLayout: ()=>
                console.log("== Setting preview layout ==")
                container = angular.element('#cards-wrapper')
                container.isotope('destroy')
                # change class of drive-app div
                angular.element("#drive-app").addClass("preview-mode")
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
                
        exit: =>
                angular.element("#drive-app").removeClass("preview-mode")
                @$state.transitionTo('bucket')
                @$timeout(()=>
                        @$scope.runIsotope()
                ,100
                )
                return true
                
        addLabels: (fileId)=>
                params =
                        filesIds: fileId
                @$state.transitionTo('bucket.labellisation', params)
                
        openFile: =>
                @$window.open(config.bucket_preview_uri + @$scope.file.file)
        
        openForEdition: (fileId)=>
                console.log("opening file "+fileId+" for edition")
                # patch file with object {"being_edited_by": {"pk": "9"}}
                @$scope.fileRestObject.patch({"being_edited_by": {"pk": @$scope.authVars.profile_id}}).then((result)=>
                        console.debug(" file is now being updated " )
                        @$scope.file.being_edited_by = 
                                username: @$scope.authVars.username
                        @$scope.openFile()
                )
        
        cancelOpenForEdition: (fileId)=>
                console.log("Cancelling opening file "+fileId+" for edition")
                # patch file with object {}
                @$scope.fileRestObject.patch({"being_edited_by": {}}).then((result)=>
                        console.debug(" file is no longer being updated " )
                        @$scope.file.being_edited_by = null
                )
                        
                        
class FileLabellisationCtrl
# designed for multifiles, but multifile selection is still missing
        constructor:  (@$scope, @Restangular, @$stateParams, @$state, @$filter, @$timeout) ->
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
                         @$scope.suggestedTags = result.slice(0,15)
                )
                console.log("[FileLabellisation] suggested tags : "+@$scope.suggestedTags)

                # needed to avoid default browser's autocomplete
                @$timeout(()->
                        angular.element("#tagSearchField_value").attr("autocomplete", "off")
                ,1000
                )
                
                # Watch selection of suggested (autocomplete) tag and add it
                @$scope.tagAutocompleteUrl = config.rest_uri+"/bucketfile/bucket/"+@$scope.currentBucket+"/search?auto="
                @$scope.tag_search_form =
                        query: ""
                @$scope.$watch('tag_search_form.query.title', (newValue, oldValue) =>
                        console.debug("[FileLabellisation] Suggested Tag selected : "+@$scope.tag_search_form.query.title)
                        if @$scope.tag_search_form.query
                                newTag = 
                                        name: @$scope.tag_search_form.query.title
                                found = @$scope.taggingQueue[@$scope.files[0].id].some((el)->
                                        return el.name == newTag.name
                                )
                                if (!found) 
                                        @$scope.taggingQueue[@$scope.files[0].id].push(newTag)
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
                @$scope.cancel = ()=>
                        @$state.transitionTo(@$state.previous, @$state.previous_params)
                @$scope.goToFile = (id)=>
                        params=
                                fileId: id
                        @$state.transitionTo('bucket/file', params)
        
        addToSuggestedTags: =>
                tagString = angular.element('#tagSearchField_value').val()
                console.log("Adding a tag : " +tagString)
                tag = 
                        name: tagString
                angular.element('#tagSearchField_value').val("")
                found = @$scope.taggingQueue[@$scope.files[0].id].some((el)->
                                        return el.name == tag.name
                )
                if (!found) 
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
        constructor: (@$scope, @filerService, @$timeout, @Restangular, $rootScope) ->
                @$scope.files = []
                # FIXME: get current bucket from session
                @$scope.currentBucket = 1
                @$scope.selectedTags = []
                @$scope.search_form =
                        query: ""
                @$scope.searchFilesObject = @Restangular.one('bucketfile').one('bucket', @$scope.currentBucket)
                @$scope.searchFilesObject.getList('search',{}).then((result) =>
                        @$scope.files = result
                        console.log(" brodcast")
                        @$scope.$broadcast('fileListComplete')
                )
                # AUTOCOMPLETE SETUP | FIXME : get root URL from config file
                @$scope.autocompleteUrl = config.rest_uri+"/bucketfile/bucket/"+@$scope.currentBucket+"/search?auto="
                # needed to avoid default browser's autocomplete
                @$timeout(()->
                        angular.element("#searchField_value").attr("autocomplete", "off")
                ,1000
                )
                
                # Methods declaration
                @$scope.updateAutocompleteURL = this.updateAutocompleteURL
                @$scope.searchFiles = this.searchFiles
                @$scope.removeTag = this.removeTag

                # Quick hack so isotope renders when file changes
                @$scope.$on('fileListComplete',  () =>
                        console.log('receive File list complete')
                        @$timeout(() =>
                                console.log(" === runIsotope within FileLIst after timeout") 
                                console.log(@$scope.isotope_container)
                                @$scope.runIsotope()
                        ,1000
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
                console.debug("adding facets: "+facets)
                @$scope.autocompleteUrl = config.rest_uri+"/bucketfile/bucket/"+@$scope.currentBucket+"/search?"+facetQuery+"&auto="                        
        
        removeTag: (tag)=>
                index = @$scope.selectedTags.indexOf(tag)
                @$scope.selectedTags.splice(index,1)
                console.debug(" New sel tags == "+@$scope.selectedTags)
                # refresh search
                this.searchFiles()
                this.updateAutocompleteURL()

        searchFiles: =>
                query = angular.element('#searchField_value').val()
                console.debug("searching with: "+query)
                #search URL : config.rest_uri+ /bucketfile/bucket/1/search?format=json&q=blabla
                @$scope.searchFilesObject.getList('search', {q: query, facet:@$scope.selectedTags }).then((result) =>
                         @$scope.files = result
                )

class FileCommentCtrl
# child controller of either FileDetail or FileList, hence the dependency on @$scope.file
        constructor: (@$scope, @Restangular, @$rootScope) ->
                @$scope.comment_form =
                        text: ""
                @$scope.submitForm = this.submitForm
                @commentsObject = @Restangular.all('bucketfilecomment')
                @commentsObject.getList({bucket_file:@$scope.file.id}).then( (result)=>
                        @$scope.comments = result
                        @$rootScope.$broadcast("new_comment")
                        console.log("New comment loaded")
                )
                
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
module.controller("FileLabellisationCtrl", ['$scope', 'Restangular', '$stateParams','$state', '$filter', '$timeout', FileLabellisationCtrl])
module.controller("FileListCtrl", ['$scope', 'filerService', '$timeout', 'Restangular', '$rootScope', FileListCtrl])
module.controller("FileCommentCtrl", ['$scope', 'Restangular','$rootScope', FileCommentCtrl])
