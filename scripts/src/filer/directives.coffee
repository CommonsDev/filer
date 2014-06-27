module = angular.module('filer.directives', [])

#module.directive("leaflet", ["$http", "$log", "$location", ($http, $log, $location) ->

module.directive('isotopeOnLoad', ($rootScope) ->
    return {
        restrict: 'A',
        link: (scope, element, attrs) ->
            console.debug("starting isotopeOnLoad directive !!")
            if (typeof $rootScope.loadCounter == 'undefined')
                $rootScope.loadCounter = 0
            image = element.find('img')
            if image.hasClass('thumbnail')
                image.bind('load', ()->
                    console.debug(" signal Card loaded", $rootScope.loadCounter)
                    scope.$emit('$cardLoaded', $rootScope.loadCounter++)
                )
        ,
        controller: ($scope, FilerService) ->
            $scope.$parent.$on('$cardLoaded', (event, data) ->
                if ($scope.$last && $scope.$index == $rootScope.loadCounter - 1)
                    $scope.$emit('$allCardsLoaded')
                    delete $rootScope.loadCounter
                    # FIXME : use initIsotope service from FilerService
                    FilerService.initIsotope()
            )
    }
)


