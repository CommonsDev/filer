angular.element(document).ready(->
        angular.module('filer', ['filer.controllers'])

        angular.module('unisson_filer', ['filer', 'ui.router', 'ngAnimate', 'restangular', 'angularFileUpload'])

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
                        templateUrl: 'views/file-list.html'
                        # templateUrl: moduleTemplateBaseUrl + 'map_new.html',
                )
                .state('bucket.file',
                        url: '/file/:fileId'
                        templateUrl: 'views/file-preview.html'
                )
                .state('bucket.upload',
                        url: '/upload'
                )
        ])

        angular.bootstrap(document, ['unisson_filer'])
)
