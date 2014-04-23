module = angular.module('filer.services', ['restangular', 'angularFileUpload'])

class FilerService
        constructor: (@$rootScope, @$compile, $fileUploader, @Restangular) ->
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
                )


# Services
module.factory('filerService', ['$rootScope', '$compile', '$fileUploader', 'Restangular', ($rootScope, $compile, $fileUploader, Restangular) ->
        return new FilerService($rootScope, $compile, $fileUploader, Restangular)
])
