module = angular.module('filer.services', ['restangular', 'angularFileUpload', 'ui.router'])

class FilerService
        constructor: (@$rootScope, @$compile, $fileUploader, @Restangular, @$state) ->
                @$rootScope.uploader = $fileUploader.create(
                        scope: @$rootScope
                        autoUpload: true
                        url: 'http://localhost:8000/bucket/upload/?format=json'
                        headers:
                                "Authorization": "ApiKey pipo:46fbf0f29a849563ebd36176e1352169fd486787" # FIXME
                        formData: [{bucket: 1}] # FIXME
                )
                @$rootScope.uploader.bind('success', (event, xhr, item, response) => 
                        console.log('Success', item, response)
                        # open labellisation for this file
                        console.log("fileID = "+response.id)
                        console.log(item)
                        @$state.transitionTo('bucket.labellisation')
                )
                @$rootScope.seeUploadedFile = (file)=>
                        filed = angular.fromJson(file)
                        console.log(file)
                        console.log(filed)
                        toParams =
                                fileId:filed.id
                        @$state.transitionTo('bucket.file', toParams)


# Services
module.factory('filerService', ['$rootScope', '$compile', '$fileUploader', 'Restangular','$state', ($rootScope, $compile, $fileUploader, Restangular, $state) ->
        return new FilerService($rootScope, $compile, $fileUploader, Restangular, $state)
])
