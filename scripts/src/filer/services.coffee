services = angular.module('filer.services', ['restangular', 'angularFileUpload', 'ui.router'])


class FilerService
        constructor: (@$rootScope, @$compile, $fileUploader, @Restangular, @$state, @$stateParams, @$http, @$timeout) ->
                @$rootScope.uploader = $fileUploader.create(
                        scope: @$rootScope
                        autoUpload: false
                        removeAfterUpload: true
                        url: config.bucket_uri
                        # FIXME : so far we set headers right after addin file, to be sure login is already done 
                        # and api key is available. There HAS to be a cleaner way
                        formData: [{bucket: $stateParams.bucketId}] # FIXME
                )
                
                @$rootScope.uploader.bind('success', (event, xhr, item, response) =>
                        console.log('Success', item, response)
                        # open labellisation for this file
                        console.log("fileID = "+response.id)
                        console.log(item)
                        @$rootScope.panel = ''
                        @$state.go('bucket.labellisation', {filesIds: response.id})
                )

                @$rootScope.uploader.bind('afteraddingfile', (event, item) =>
                        # we set headers at this moment for we're then sure to have the authorization key. FIXME !!!!
                        item.headers =
                               "Authorization": @$http.defaults.headers.common.Authorization
                        @$rootScope.panel = 'upload'
                )

                @$rootScope.seeUploadedFile = (file)=>
                        filed = angular.fromJson(file)
                        toParams =
                                fileId:filed.id
                        @$state.transitionTo('bucket.file', toParams)

                @$rootScope.exitPreview = ()=>
                        angular.element("#drive-app").removeClass("preview-mode")
                        @$state.go('bucket')
                        @$timeout(()=>
                                @$rootScope.runIsotope()
                        ,300
                        )
                        return true

                @$rootScope.exitFiler = ()=>
                        @$state.go('home')
                 
                @$rootScope.deleteFile = (fileId)=>
                        @Restangular.one('bucket/file', fileId).remove().then(()=>
                                console.debug(" File deleted ! " )
                                #reload home
                                console.log("reloading to home")
                                @$state.go('bucket',{}, {reload:true})
                                )
                @$rootScope.assignToGroup = (groupId)=>
                        console.debug(" target group : ", groupId)
                        postData = {
                            group_id:groupId
                        }
                        @Restangular.one('bucket/bucket',$stateParams.bucketId).post('assign', postData).then((message)=>
                                console.debug("bucket assigned to group : ", message)

                                )
                # Isotope stuff
                @$rootScope.runIsotope = ()=>
                        @$rootScope.isotope_container = angular.element('#cards-wrapper').isotope(
                                console.log(" OO- Running isotope ")
                                itemSelector: '.element'
                                layoutMode: 'masonry'
                        )

# Services
services.factory('filerService', ['$rootScope', '$compile', '$fileUploader', 'Restangular','$state', '$stateParams','$http', '$timeout',($rootScope, $compile, $fileUploader, Restangular, $state, $stateParams, $http, $timeout) ->
        return new FilerService($rootScope, $compile, $fileUploader, Restangular, $state, $stateParams, $http, $timeout)
])

# Restangular factories
services.factory('Buckets', (Restangular) ->
        return Restangular.service('bucket/bucket')
)
