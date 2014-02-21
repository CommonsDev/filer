angular.element(document).ready(->
        angular.module('filer', ['filer.controllers', 'filer.services'])

        angular.module('unisson_filer', ['filer', 'ui.router', 'ngAnimate', 'restangular'])

        # CORS
        .config(['$httpProvider', ($httpProvider) ->
                $httpProvider.defaults.useXDomain = true
                delete $httpProvider.defaults.headers.common['X-Requested-With']
        ])

        # Tastypie
        .config((RestangularProvider) ->
                RestangularProvider.setBaseUrl(config.rest_uri)
                RestangularProvider.setDefaultHeaders({"Authorization": "ApiKey pipo:46fbf0f29a849563ebd36176e1352169fd486787"});
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
                $urlRouterProvider.otherwise("/bucket")

                $stateProvider.state('bucket',
                        url: '/bucket'
                        views:
                                filelist:
                                        templateUrl: "views/file-list.html"
                )
                .state('bucket.file',
                        url: '/file/:fileId'
                        templateUrl: 'views/file-preview.html'
                )
                .state('bucket.upload',
                        url: '/upload'
                )
        ])

        console.debug("running angular app...")
        angular.bootstrap(document, ['unisson_filer'])
)
