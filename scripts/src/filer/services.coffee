module = angular.module('filer.services', ['restangular', 'angularFileUpload', 'ui.router'])

class FilerService
        constructor: (@$rootScope, @$compile, $fileUploader, @Restangular, @$state) ->
                @$rootScope.uploader = $fileUploader.create(
                        scope: @$rootScope
                        autoUpload: true
                        url: 'http://localhost:8000/bucket/upload/?format=json' # FIXME
                        headers:
                                "Authorization": "ApiKey pipo:46fbf0f29a849563ebd36176e1352169fd486787" # FIXME
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
module.factory('filerService', ['$rootScope', '$compile', '$fileUploader', 'Restangular','$state', ($rootScope, $compile, $fileUploader, Restangular, $state) ->
        return new FilerService($rootScope, $compile, $fileUploader, Restangular, $state)
])
