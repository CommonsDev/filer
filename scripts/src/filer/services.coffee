module = angular.module('filer.services', ['restangular', 'angularFileUpload'])

class FilerService
        constructor: (@$rootScope, @$compile, $fileUploader, @Restangular) ->
                @$rootScope.uploader = $fileUploader.create(
                        scope: @$rootScope
                        autoUpload: true
                        url: 'http://localhost:8000/bucket/upload/'
                        formData: [{bucket: 1}] # FIXME
                )



# Services
module.factory('filerService', ['$rootScope', '$compile', '$fileUploader', 'Restangular', ($rootScope, $compile, $fileUploader, Restangular) ->
        return new FilerService($rootScope, $compile, $fileUploader, Restangular)
])
