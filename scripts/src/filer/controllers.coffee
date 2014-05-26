module = angular.module('filer.controllers', ['restangular', 'filer.services', 'angular-unisson-auth'])

class BucketNewCtrl
        constructor: (@$scope, @$state, @Buckets) ->
                @$scope.createBucket = this.createBucket

        createBucket: =>
                @Buckets.post({}).then((bucket) =>
                        @$state.go('bucket', {bucketId: bucket.id})
                )


class BucketListCtrl
        constructor: (@$scope, @Buckets) ->
                @$scope.buckets = @Buckets.getList().$object

class ToolbarCtrl
        constructor: (@$scope, @filerService) ->
                @$scope.panel = null
                @$scope.filerService = @filerService

class FileDetailCtrl
        constructor: (@$scope, @filerService, @Restangular, @$stateParams, @$state, @$timeout, @$window) ->
                console.debug("started file detail on file:"+ @$stateParams.fileId)
                #        by child controllers (as FileCommentCtrl) before the promisse is realized
                @$scope.file =
                        id: @$stateParams.fileId
                        being_edited_by : {}

                @$scope.fileRestObject = @Restangular.one('bucket/file', @$scope.file.id)
                @$scope.fileRestObject.get().then((result)=>
                        @$scope.file = result
                )

                # if files is empty, wait for fileListComplete event
                if @$scope.files.length <= 0
                        console.debug("== waiting for files list to complete")
                        @$scope.$on('fileListComplete',  () =>
                                console.debug('receive File list complete [FileDetailCtr]')
                                @$timeout(() =>
                                        @$scope.setPreviewLayout() 
                                ,2000
                                )
                        )
                else
                        console.debug("== will set eview layout now !")
                        @$timeout(() =>
                                @$scope.setPreviewLayout()
                        ,30
                        )

                ## Methods ##
                # CReate preview layout FIXME (so ugly!!)
                @$scope.setPreviewLayout = this.setPreviewLayout
                @$scope.openForEdition = this.openForEdition
                @$scope.openFile = this.openFile
                @$scope.addLabels = this.addLabels 
                @$scope.cancelOpenForEdition = this.cancelOpenForEdition

        setPreviewLayout: ()=>
                console.debug("== Setting preview layout ==")
                container = angular.element('#cards-wrapper')
                container.isotope('destroy')
                # change class of drive-app div
                angular.element("#drive-app").addClass("preview-mode")
                # fetch the index of the current element
                listItemPreviewed = angular.element('.previewed').parent('.element')
                index = angular.element('.element').index(listItemPreviewed)
                console.debug(" element index =" + index )
                # get the width of the container, here we are talking about cards-wrapper
                containerWidth = angular.element('#cards-wrapper').width()
                cardsNumberPerLine = parseInt(containerWidth / 252);
                currentLine = parseInt(index / cardsNumberPerLine);
                console.debug(" cardsNumberPerLine =" + cardsNumberPerLine )
                console.debug(" currentLine =" + currentLine )
                # get the element after which we will have to inject the preview panel
                lastElement = currentLine * cardsNumberPerLine + cardsNumberPerLine
                cardsNumberTotal = angular.element('.element').length
                console.debug(" cardsNumberTotal =" + cardsNumberTotal )
                if lastElement > cardsNumberTotal
                        lastElement = cardsNumberTotal
                # move the preview panel in the right place
                console.debug(" last element index =" + lastElement )
                angular.element('#preview-panel-wrapper').insertAfter(angular.element('.element').eq(lastElement - 1))

        addLabels: (fileId)=>
                @$state.go('bucket.labellisation', {filesIds: fileId})

        openFile: =>
                @$window.open(config.bucket_preview_uri + @$scope.file.file)

        openForEdition: (fileId)=>
                console.debug("opening file "+fileId+" for edition by : ", @$scope.authVars.user)
                # patch file with object {"being_edited_by": resource_uri}
                @$scope.fileRestObject.patch({"being_edited_by": @$scope.authVars.user.resource_uri}).then((result)=>
                        console.debug(" file is now being updated " )
                        @$scope.file.being_edited_by =
                                username: @$scope.authVars.username
                        @$scope.openFile()
                )
        
        cancelOpenForEdition: (fileId)=>
                console.debug("Cancelling opening file "+fileId+" for edition")
                # patch file with object {}
                @$scope.fileRestObject.patch({"being_edited_by": {}}).then((result)=>
                        console.debug(" file is no longer being updated " )
                        @$scope.file.being_edited_by = null
                )
                        

class FileLabellisationCtrl
# designed for multifiles, but multifile selection is still missing
        constructor:  (@$scope, @Restangular, @$stateParams, @$state, @$filter, @$timeout) ->
                console.debug(" labellilabello started !!")

                # Populating file if provided as stateParam
                @$scope.files = []
                @$scope.taggingQueue = {}
                if @$stateParams.filesIds
                        @Restangular.one('bucket/file').one("set", @$stateParams.filesIds).getList().then((result) =>
                                @$scope.files = result
                                # Populating tagging queue with current tags if any
                                for file in @$scope.files
                                        do(file)=>
                                                @$scope.taggingQueue[file.id] = file.tags
                        )

                # Populating suggested (most used) tags
                @$scope.suggestedTags = []
                @$scope.tagsList = @Restangular.one('bucket/file').one('bucket', @$stateParams.bucketId)
                @$scope.tagsList.getList('search',{ auto: ""}).then((result) =>
                         @$scope.suggestedTags = result.slice(0,15)
                )
                console.debug("[FileLabellisation] suggested tags : "+@$scope.suggestedTags)

                # needed to avoid default browser's autocomplete
                @$timeout(()->
                        angular.element("#tagSearchField_value").attr("autocomplete", "off")
                ,1000
                )

                # Watch selection of existing tag and add to suggested tags
                @$scope.tagAutocompleteUrl = "#{config.rest_uri}/bucket/file/bucket/#{@$stateParams.bucketId}/search?auto="
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
                        @$state.go('bucket', {}, {reload:true})
                @$scope.goToFile = (id) =>
                        @$state.go('bucket.file', {fileId: id})
                 @$scope.cancel = ()=>
                        @$state.transitionTo(@$state.previous, @$state.previous_params)

        addToSuggestedTags: =>
                tagString = angular.element('#tagSearchField_value').val()
                console.debug(tagString)
                tag =
                        name: tagString
                angular.element('#tagSearchField_value').val("")
                found = @$scope.taggingQueue[@$scope.files[0].id].some((el)->
                                        return el.name == tag.name
                )
                if (!found) 
                        @$scope.taggingQueue[@$scope.files[0].id].push(tag)


        addTag: (fileId, tag)=>
                console.debug( "++ adding tag : " + tag.name + " to file :" +fileId)
                file = @$filter('filter')(@$scope.files, {id : fileId})[0]
                if @$scope.taggingQueue[fileId].indexOf(tag) == -1
                        @$scope.taggingQueue[fileId].push(tag)
                console.debug("+new tagging queue+")
                console.debug(@$scope.taggingQueue)

        removeTag: (fileId, tag)=>
                console.debug( "++ removing tag : " + tag.name + " from file :" +fileId)
                index = @$scope.taggingQueue[fileId].indexOf(tag)
                @$scope.taggingQueue[fileId].splice(index, 1)
                console.debug("+new tagging queue+")
                console.debug(@$scope.taggingQueue)

        updateTags: =>
                console.debug("updating tags")
                # loop in tagging queue, and do a PATCH
                for fileId, tags of @$scope.taggingQueue
                        do (fileId, tags)=>
                                console.debug("tags for file: "+fileId)
                                tagsObject =
                                        tags:tags
                                console.debug(tagsObject)
                                fileRestObject = @Restangular.one('bucket/file', fileId)
                                fileRestObject.patch(tagsObject).then(()=>
                                        console.debug(" tags updated ! " )
                                        )
                @$scope.goHome()


class FileListCtrl
        constructor: (@$scope, @filerService, @$timeout, @$stateParams, @Restangular, @$rootScope) ->
                @$scope.files = []
                # FIXME: get current bucket from session
                @$scope.selectedTags = []
                @$scope.search_form =
                        query: ""
                @$scope.searchFilesObject = @Restangular.one('bucket/file').one('bucket', @$stateParams.bucketId)
                @$scope.searchFilesObject.getList('search',{}).then((result) =>
                        @$scope.files = result
                        console.debug(" brodcast")
                        @$scope.$broadcast('fileListComplete')
                )

                # AUTOCOMPLETE SETUP | FIXME : get root URL from config file
                @$scope.autocompleteUrl = "#{config.rest_uri}/bucket/file/bucket/#{@$stateParams.bucketId}/search?auto="
                # needed to avoid default browser's autocomplete
                @$timeout(->
                        angular.element("#searchField_value").attr("autocomplete", "off")
                , 1000)

                # Methods declaration
                @$scope.updateAutocompleteURL = this.updateAutocompleteURL
                @$scope.searchFiles = this.searchFiles
                @$scope.removeTag = this.removeTag

                # Quick hack so isotope renders when file changes
                @$scope.$on('fileListComplete',  () =>
                        console.debug('receive File list complete')
                        @$timeout(=>
                                console.debug(" === runIsotope within FileLIst after timeout")
                                console.debug(@$scope.isotope_container)
                                @$scope.runIsotope()
                        ,2000
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
                @$scope.autocompleteUrl = "#{config.rest_uri}/bucket/file/bucket/#{@$stateParams.bucketId}/search?#{facetQuery}&auto="

        removeTag: (tag)=>
                index = @$scope.selectedTags.indexOf(tag)
                @$scope.selectedTags.splice(index,1)
                console.debug(" New sel tags == "+@$scope.selectedTags)
                # refresh search
                this.searchFiles()
                this.updateAutocompleteURL()

        searchFiles: =>
                # leave preview mode if activated
                @$scope.exitPreview()
                query = angular.element('#searchField_value').val()
                console.debug("searching with: "+query)
                #search URL : config.rest_uri+ /bucket/1/search?format=json&q=blabla
                @$scope.searchFilesObject.getList('search', {q: query, facet:@$scope.selectedTags }).then((result) =>
                         @$scope.files = result
                )

class FileCommentCtrl
# child controller of either FileDetail or FileList, hence the dependency on @$scope.file
        constructor: (@$scope, @Restangular, @$rootScope) ->
                @$scope.comment_form =
                        text: ""
                @$scope.submitForm = this.submitForm
                @commentsObject = @Restangular.all('bucket/filecomment')
                @commentsObject.getList({bucket_file:@$scope.file.id}).then( (result)=>
                        @$scope.comments = result
                        @$rootScope.$broadcast("new_comment")
                        console.debug("New comment loaded")
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

module.controller("ToolbarCtrl", ['$scope', 'filerService', ToolbarCtrl])

module.controller("FileDetailCtrl", ['$scope', 'filerService', 'Restangular', '$stateParams','$state', '$timeout', '$window', FileDetailCtrl])
module.controller("FileLabellisationCtrl", ['$scope', 'Restangular', '$stateParams','$state', '$filter', '$timeout', FileLabellisationCtrl])
module.controller("FileListCtrl", ['$scope', 'filerService', '$timeout', '$stateParams', 'Restangular', '$rootScope', FileListCtrl])
module.controller("FileCommentCtrl", ['$scope', 'Restangular','$rootScope', FileCommentCtrl])

module.controller("BucketNewCtrl", ['$scope', '$state', 'Buckets', BucketNewCtrl])
module.controller("BucketListCtrl", ['$scope', 'Buckets', BucketListCtrl])
