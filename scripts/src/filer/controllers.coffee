module = angular.module('filer.controllers', ['restangular'])

class FileListCtrl
        constructor: (@$scope, @Restangular) ->
                @$scope.files = []

                @Restangular.one('notes', 1).get().then((bucket)=>
                        console.debug("youpi")
                        console.debug(bucket)
                        @$scope.files = bucket.files
                        )

module.controller("FileListCtrl", ['$scope', 'Restangular', FileListCtrl])