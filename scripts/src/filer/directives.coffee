module = angular.module('filer.directives', [])

#module.directive("leaflet", ["$http", "$log", "$location", ($http, $log, $location) ->


module.directive('fileListing', ()->
    
	return {
		restrict: "E"
		scope:
		  filesNumber: "@filesNumber"
		template: "<span> FILE LISTING </span>"

		link: ($scope)->
			#$scope.filesNumber = 10
			console.debug('file Listing directive started with '+$scope.filesNumber+ ' files')
	}
)
