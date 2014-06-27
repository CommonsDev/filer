services = angular.module('filer.services', ['restangular', 'angularFileUpload', 'ui.router'])


class FilerService
        constructor: (@$rootScope, @$compile, $fileUploader, @Restangular, @$state, @$stateParams, @$http, @$timeout) ->
                @$rootScope.uploader = $fileUploader.create(
                        scope: @$rootScope
                        autoUpload: false
                        removeAfterUpload: true
                        url: config.bucket_uri
                        formData: [{bucket: $stateParams.bucketId}] 
                )
                
                @$rootScope.uploader.bind('success', (event, xhr, item, response) =>
                        @$rootScope.panel = ''
                        # FIXME : add file to files list and then refresh isotope
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
                        console.debug(" Exit preview mode !")
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
                @$rootScope.assignBucketToGroup = (groupId)=>
                        postData = {
                            group_id:groupId
                        }
                        @Restangular.one('bucket/bucket',$stateParams.bucketId).post('assign', {group_id:groupId}).then((message)=>
                                console.debug("bucket assigned to group : ", message)
                                $("#assignation").fadeIn('slow').delay(1000).fadeOut('slow')
                                @$rootScope.panel = ''
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
