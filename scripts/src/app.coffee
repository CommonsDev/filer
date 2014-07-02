angular.element(document).on('ready page:load', ->
        angular.module('filer', ['filer.controllers', 'filer.services', 'filer.directives'])

        angular.module('unisson_filer', ['filer', 'ui.router', 'ngAnimate', 'restangular', 'angularFileUpload', 'angucomplete', 'angular-unisson-auth'])

        # Token
        .config(['TokenProvider', '$locationProvider', (TokenProvider, $locationProvider) ->
                TokenProvider.extendConfig({
                        clientId: 'config.cliend_id', #FIXME: does not let me load this from config
                        redirectUri: config.rootUrl+'oauth2callback.html',
                        scopes: ["https://www.googleapis.com/auth/userinfo.email",
                                "https://www.googleapis.com/auth/userinfo.profile"],
                        });
                ])

        # CORS
        .config(['$httpProvider', ($httpProvider) ->
                $httpProvider.defaults.useXDomain = true
                delete $httpProvider.defaults.headers.common['X-Requested-With']
        ])

        # Tastypie
        .config((RestangularProvider) ->
                RestangularProvider.setBaseUrl(config.rest_uri)
                #RestangularProvider.setDefaultHeaders({"Authorization": "ApiKey pipo:46fbf0f29a849563ebd36176e1352169fd486787"});
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

                $stateProvider.state('home',
                        url: '/'
                        templateUrl: 'views/home.html'
                        controller: 'BucketNewCtrl'
                )

                $stateProvider.state('home.my_buckets',
                        url: '/mybuckets',
                        templateUrl: "views/home_sidebar.html",
                        controller: 'BucketListCtrl'
                )

                .state('bucket',
                        url: '/:bucketId'
                        templateUrl: "views/file-list.html"
                        controller: 'FileListCtrl'
                )
                .state('bucket.file',
                        url: '/file/:fileId'
                        templateUrl: 'views/file-preview.html'
                        controller: 'FileDetailCtrl'
                )
                .state('bucket.upload',
                        url: '/upload'
                )
                .state('bucket.labellisation',
                        url: '/labellisation/:filesIds'
                        templateUrl: 'views/labellisation-overlay.html'
                        controller: 'FileLabellisationCtrl'
                )
        ])

        # Unisson auth config
        .config((loginServiceProvider) ->
                loginServiceProvider.setBaseUrl(config.loginBaseUrl)
        )

        .config((loginServiceProvider) ->
                loginServiceProvider.setBaseUrl(config.loginBaseUrl)
        )

        .run(['$rootScope', 'loginService', ($rootScope, loginService) ->
                $rootScope.config = config;

                $rootScope.homeStateName = config.homeStateName || 'home'
                $rootScope.loginService = loginService
        ])

        # Ugly Fix for autofill on forms
        .directive('formAutofillFix', ->
                (scope, elem, attrs) ->
                        # Fixes Chrome bug: https://groups.google.com/forum/#!topic/angular/6NlucSskQjY
                        elem.prop 'method', 'POST'

                        # Fix autofill issues where Angular doesn't know about autofilled inputs
                        if attrs.ngSubmit
                                setTimeout ->
                                        elem.unbind('submit').submit (e) ->
                                                e.preventDefault()
                                                elem.find('input, textarea, select').trigger('input').trigger('change').trigger 'keydown'
                                                scope.$apply attrs.ngSubmit
                                , 0
        )

        console.debug("running angular app...")
        angular.bootstrap(document, ['unisson_filer'])
)
