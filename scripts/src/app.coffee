angular.module('filer', ['filer.controllers'])

angular.module('unisson_filer', ['ui.router', 'ngAnimate', 'restangular', 'filer'])

# CORS
.config(['$httpProvider', ($httpProvider) ->
        $httpProvider.defaults.useXDomain = true
        delete $httpProvider.defaults.headers.common['X-Requested-With']
])

# Tastypie
.config((RestangularProvider) ->
        RestangularProvider.setBaseUrl(config.rest_uri)

        # Tastypie patch
        RestangularProvider.setResponseExtractor((response, operation, what, url) ->
                newResponse = null;

                if operation is "getList"
                        newResponse = response.objects
                        newResponse.metadata = response.meta
                else
                        newResponse = response

                return newResponse
        )
)


# URI config
.config(['$locationProvider', '$stateProvider', '$urlRouterProvider', ($locationProvider, $stateProvider, $urlRouterProvider) ->
                                $locationProvider.html5Mode(config.useHtml5Mode)
                                $urlRouterProvider.otherwise("/")

                                $stateProvider.state('index',
                                        url: '/'
                                        # controller: 'MapNewCtrl'
                                        page_title: 'Bienvenue'
                                        # templateUrl: moduleTemplateBaseUrl + 'map_new.html',
                                )
                        ])


angular.bootstrap(document, ['unisson_filer'])