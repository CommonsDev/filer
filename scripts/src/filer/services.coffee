module = angular.module('filer.services', ['restangular', 'angularFileUpload', 'ui.router'])

class FilerService
        constructor: (@$rootScope, @$compile, $fileUploader, @Restangular, @$state, @$http) ->
                @$rootScope.uploader = $fileUploader.create(
                        scope: @$rootScope
                        autoUpload: false
                        removeAfterUpload: true
                        url: 'http://localhost:8000/bucket/upload/?format=json' #FIXME
                        # FIXME : so far we set headers right after addin file, to be sure login is already done 
                        # and api key is available. There HAS to be a cleaner way
                        formData: [{bucket: 1}] # FIXME
                )
                
                @$rootScope.uploader.bind('success', (event, xhr, item, response) => 
                        console.log('Success', item, response)
                        # open labellisation for this file
                        console.log("fileID = "+response.id)
                        console.log(item)
                        toParams =
                                filesIds:response.id
                        @$state.transitionTo('bucket.labellisation', toParams)
                )
                
                @$rootScope.uploader.bind('afteraddingfile', (event, item) =>
                        # we set headers at this moment for we're then sure to have the authorization key
                        item.headers =
                               "Authorization": @$http.defaults.headers.common.Authorization 
                        @$rootScope.panel = 'upload'
                )
                
                @$rootScope.seeUploadedFile = (file)=>
                        filed = angular.fromJson(file)
                        toParams =
                                fileId:filed.id
                        @$state.transitionTo('bucket.file', toParams)
                
                @$rootScope.deleteFile = (fileId)=>
                        @Restangular.one('bucketfile', fileId).remove().then(()=>
                                console.debug(" File deleted ! " )
                                #reload home
                                console.log("reloading to home")
                                @$state.go('bucket',{}, {reload:true})
                                )
                
                @$rootScope.runIsotope = ()=>
                        # Run isotope
                        console.log(" RUN ISOTOPE = ")
                        container = angular.element('#cards-wrapper')
                        container.isotope(
                                itemSelector: '.element'
                                layoutMode: 'masonry'
                        )
                        
# Services
module.factory('filerService', ['$rootScope', '$compile', '$fileUploader', 'Restangular','$state', '$http', ($rootScope, $compile, $fileUploader, Restangular, $state, $http) ->
        return new FilerService($rootScope, $compile, $fileUploader, Restangular, $state, $http)
])
