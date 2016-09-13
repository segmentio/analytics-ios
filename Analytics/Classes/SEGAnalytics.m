#import <UIKit/UIKit.h>
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"
#import "SEGIntegrationFactory.h"
#import "SEGIntegration.h"
#import "SEGSegmentIntegrationFactory.h"
#import "UIViewController+SEGScreen.h"
#import "SEGStoreKitTracker.h"
#import "SEGHTTPClient.h"
#import "SEGStorage.h"
#import "SEGFileStorage.h"
#import "SEGUserDefaultsStorage.h"
#import <objc/runtime.h>

static SEGAnalytics *__sharedInstance = nil;
NSString *SEGAnalyticsIntegrationDidStart = @"io.segment.analytics.integration.did.start";
NSString *const SEGAnonymousIdKey = @"SEGAnonymousId";
NSString *const kSEGAnonymousIdFilename = @"segment.anonymousId";


@interface SEGAnalyticsConfiguration ()

@property (nonatomic, copy, readwrite) NSString *writeKey;
@property (nonatomic, strong, readonly) NSMutableArray *factories;

@end


@implementation SEGAnalyticsConfiguration

+ (instancetype)configurationWithWriteKey:(NSString *)writeKey
{
    return [[SEGAnalyticsConfiguration alloc] initWithWriteKey:writeKey];
}

- (instancetype)initWithWriteKey:(NSString *)writeKey
{
    if (self = [self init]) {
        self.writeKey = writeKey;
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.shouldUseLocationServices = NO;
        self.enableAdvertisingTracking = YES;
        self.shouldUseBluetooth = NO;
        self.flushAt = 20;
        _factories = [NSMutableArray array];
        [_factories addObject:[SEGSegmentIntegrationFactory instance]];
    }
    return self;
}

- (void)use:(id<SEGIntegrationFactory>)factory
{
    [self.factories addObject:factory];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%p:%@, %@>", self, self.class, [self dictionaryWithValuesForKeys:@[ @"writeKey", @"shouldUseLocationServices", @"flushAt" ]]];
}

@end


@interface SEGAnalytics ()

@property (nonatomic, strong) NSDictionary *cachedSettings;
@property (nonatomic, strong) SEGAnalyticsConfiguration *configuration;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSMutableArray *messageQueue;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, strong) NSArray *factories;
@property (nonatomic, strong) NSMutableDictionary *integrations;
@property (nonatomic, strong) NSMutableDictionary *registeredIntegrations;
@property (nonatomic) volatile BOOL initialized;
@property (nonatomic, strong) SEGStoreKitTracker *storeKitTracker;
@property (nonatomic, copy) NSString *cachedAnonymousId;
@property (nonatomic, strong) SEGHTTPClient *httpClient;
@property (nonatomic, strong) NSURLSessionDataTask *settingsRequest;
@property (nonatomic, strong) id<SEGStorage> storage;

@end


@implementation SEGAnalytics

@synthesize cachedSettings = _cachedSettings;

+ (void)setupWithConfiguration:(SEGAnalyticsConfiguration *)configuration
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[self alloc] initWithConfiguration:configuration];
    });
}

- (instancetype)initWithConfiguration:(SEGAnalyticsConfiguration *)configuration
{
    NSCParameterAssert(configuration != nil);

    if (self = [self init]) {
        self.configuration = configuration;
        self.enabled = YES;
        self.serialQueue = seg_dispatch_queue_create_specific("io.segment.analytics", DISPATCH_QUEUE_SERIAL);
        self.messageQueue = [[NSMutableArray alloc] init];
        self.factories = [configuration.factories copy];
        self.integrations = [NSMutableDictionary dictionaryWithCapacity:self.factories.count];
        self.registeredIntegrations = [NSMutableDictionary dictionaryWithCapacity:self.factories.count];
        self.configuration = configuration;
        self.cachedAnonymousId = [self loadOrGenerateAnonymousID:NO];
        self.httpClient = [[SEGHTTPClient alloc] initWithRequestFactory:configuration.requestFactory];
#if TARGET_OS_TV
        self.storage = [[SEGUserDefaultsStorage alloc] initWithDefaults:[NSUserDefaults standardUserDefaults] namespacePrefix:nil crypto:configuration.crypto];
#else
        self.storage = [[SEGFileStorage alloc] initWithFolder:[SEGFileStorage applicationSupportDirectoryURL] crypto:configuration.crypto];
#endif

        // Update settings on each integration immediately
        [self refreshSettings];

        // Attach to application state change hooks
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

        // Update settings on foreground
        [nc addObserver:self selector:@selector(onAppForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

        // Pass through for application state change events
        for (NSString *name in @[ UIApplicationDidEnterBackgroundNotification,
                                  UIApplicationDidFinishLaunchingNotification,
                                  UIApplicationWillEnterForegroundNotification,
                                  UIApplicationWillTerminateNotification,
                                  UIApplicationWillResignActiveNotification,
                                  UIApplicationDidBecomeActiveNotification ]) {
            [nc addObserver:self selector:@selector(handleAppStateNotification:) name:name object:nil];
        }

        if (configuration.recordScreenViews) {
            [UIViewController seg_swizzleViewDidAppear];
        }
        if (configuration.trackInAppPurchases) {
            _storeKitTracker = [SEGStoreKitTracker trackTransactionsForAnalytics:self];
        }

        [self trackApplicationLifecycleEvents:configuration.trackApplicationLifecycleEvents];

#if !TARGET_OS_TV
        if (configuration.trackPushNotifications && configuration.launchOptions) {
            NSDictionary *remoteNotification = configuration.launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
            if (remoteNotification) {
                [self trackPushNotification:remoteNotification fromLaunch:YES];
            }
        }
#endif
    }
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

NSString *const SEGVersionKey = @"SEGVersionKey";
NSString *const SEGBuildKey = @"SEGBuildKey";

- (void)trackApplicationLifecycleEvents:(BOOL)trackApplicationLifecycleEvents
{
    if (!trackApplicationLifecycleEvents) {
        return;
    }

    NSString *previousVersion = [[NSUserDefaults standardUserDefaults] stringForKey:SEGVersionKey];
    NSInteger previousBuild = [[NSUserDefaults standardUserDefaults] integerForKey:SEGBuildKey];

    NSString *currentVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    NSInteger currentBuild = [[[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"] integerValue];

    if (!previousBuild) {
        [self track:@"Application Installed" properties:@{
            @"version" : currentVersion,
            @"build" : @(currentBuild)
        }];
    } else if (currentBuild != previousBuild) {
        [self track:@"Application Updated" properties:@{
            @"previous_version" : previousVersion,
            @"previous_build" : @(previousBuild),
            @"version" : currentVersion,
            @"build" : @(currentBuild)
        }];
    }

    [self track:@"Application Opened" properties:@{
        @"version" : currentVersion,
        @"build" : @(currentBuild)
    }];

    [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:SEGVersionKey];
    [[NSUserDefaults standardUserDefaults] setInteger:currentBuild forKey:SEGBuildKey];
}

- (void)onAppForeground:(NSNotification *)note
{
    [self refreshSettings];
}

- (void)handleAppStateNotification:(NSNotification *)note
{
    SEGLog(@"Application state change notification: %@", note.name);
    static NSDictionary *selectorMapping;
    static dispatch_once_t selectorMappingOnce;
    dispatch_once(&selectorMappingOnce, ^{
        selectorMapping = @{
            UIApplicationDidFinishLaunchingNotification :
                NSStringFromSelector(@selector(applicationDidFinishLaunching:)),
            UIApplicationDidEnterBackgroundNotification :
                NSStringFromSelector(@selector(applicationDidEnterBackground)),
            UIApplicationWillEnterForegroundNotification :
                NSStringFromSelector(@selector(applicationWillEnterForeground)),
            UIApplicationWillTerminateNotification :
                NSStringFromSelector(@selector(applicationWillTerminate)),
            UIApplicationWillResignActiveNotification :
                NSStringFromSelector(@selector(applicationWillResignActive)),
            UIApplicationDidBecomeActiveNotification :
                NSStringFromSelector(@selector(applicationDidBecomeActive))
        };
    });
    SEL selector = NSSelectorFromString(selectorMapping[note.name]);
    if (selector) {
        [self callIntegrationsWithSelector:selector arguments:nil options:nil sync:true];
    }
}

#pragma mark - Public API

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%p:%@, %@>", self, [self class], [self dictionaryWithValuesForKeys:@[ @"configuration" ]]];
}

#pragma mark - Analytics API

#pragma mark - Identify

- (void)identify:(NSString *)userId
{
    [self identify:userId traits:nil options:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits
{
    [self identify:userId traits:traits options:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    NSCAssert2(userId.length > 0 || traits.count > 0, @"either userId (%@) or traits (%@) must be provided.", userId, traits);

    NSString *anonymousId = [options objectForKey:@"anonymousId"];
    if (anonymousId) {
        [self saveAnonymousId:anonymousId];
    } else {
        anonymousId = self.cachedAnonymousId;
    }

    SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc] initWithUserId:userId
                                                                 anonymousId:anonymousId
                                                                      traits:SEGCoerceDictionary(traits)
                                                                     context:SEGCoerceDictionary([options objectForKey:@"context"])
                                                                integrations:[options objectForKey:@"integrations"]];

    [self callIntegrationsWithSelector:NSSelectorFromString(@"identify:")
                             arguments:@[ payload ]
                               options:options
                                  sync:false];
}

#pragma mark - Track

- (void)track:(NSString *)event
{
    [self track:event properties:nil options:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties
{
    [self track:event properties:properties options:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    NSCAssert1(event.length > 0, @"event (%@) must not be empty.", event);

    SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:event
                                                           properties:SEGCoerceDictionary(properties)
                                                              context:SEGCoerceDictionary([options objectForKey:@"context"])
                                                         integrations:[options objectForKey:@"integrations"]];

    [self callIntegrationsWithSelector:NSSelectorFromString(@"track:")
                             arguments:@[ payload ]
                               options:options
                                  sync:false];
}

#pragma mark - Screen

- (void)screen:(NSString *)screenTitle
{
    [self screen:screenTitle properties:nil options:nil];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties
{
    [self screen:screenTitle properties:properties options:nil];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    NSCAssert1(screenTitle.length > 0, @"screen name (%@) must not be empty.", screenTitle);

    SEGScreenPayload *payload = [[SEGScreenPayload alloc] initWithName:screenTitle
                                                            properties:SEGCoerceDictionary(properties)
                                                               context:SEGCoerceDictionary([options objectForKey:@"context"])
                                                          integrations:[options objectForKey:@"integrations"]];

    [self callIntegrationsWithSelector:NSSelectorFromString(@"screen:")
                             arguments:@[ payload ]
                               options:options
                                  sync:false];
}

#pragma mark - Group

- (void)group:(NSString *)groupId
{
    [self group:groupId traits:nil options:nil];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits
{
    [self group:groupId traits:traits options:nil];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    SEGGroupPayload *payload = [[SEGGroupPayload alloc] initWithGroupId:groupId
                                                                 traits:SEGCoerceDictionary(traits)
                                                                context:SEGCoerceDictionary([options objectForKey:@"context"])
                                                           integrations:[options objectForKey:@"integrations"]];

    [self callIntegrationsWithSelector:NSSelectorFromString(@"group:")
                             arguments:@[ payload ]
                               options:options
                                  sync:false];
}

#pragma mark - Alias

- (void)alias:(NSString *)newId
{
    [self alias:newId options:nil];
}

- (void)alias:(NSString *)newId options:(NSDictionary *)options
{
    SEGAliasPayload *payload = [[SEGAliasPayload alloc] initWithNewId:newId
                                                              context:SEGCoerceDictionary([options objectForKey:@"context"])
                                                         integrations:[options objectForKey:@"integrations"]];

    [self callIntegrationsWithSelector:NSSelectorFromString(@"alias:")
                             arguments:@[ payload ]
                               options:options
                                  sync:false];
}

- (void)trackPushNotification:(NSDictionary *)properties fromLaunch:(BOOL)launch
{
    if (launch) {
        [self track:@"Push Notification Tapped" properties:properties];
    } else {
        [self track:@"Push Notification Received" properties:properties];
    }
}

- (void)receivedRemoteNotification:(NSDictionary *)userInfo
{
    if (self.configuration.trackPushNotifications) {
        [self trackPushNotification:userInfo fromLaunch:NO];
    }
    [self callIntegrationsWithSelector:_cmd arguments:@[ userInfo ] options:nil sync:true];
}

- (void)failedToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [self callIntegrationsWithSelector:_cmd arguments:@[ error ] options:nil sync:true];
}

- (void)registeredForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSParameterAssert(deviceToken != nil);

    [self callIntegrationsWithSelector:_cmd arguments:@[ deviceToken ] options:nil sync:true];
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo
{
    [self callIntegrationsWithSelector:_cmd arguments:@[ identifier, userInfo ] options:nil sync:true];
}

- (void)continueUserActivity:(NSUserActivity *)activity
{
    [self callIntegrationsWithSelector:_cmd arguments:@[ activity ] options:nil sync:true];

    if (!self.configuration.trackDeepLinks) {
        return;
    }

    if ([activity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:activity.userInfo.count + 2];
        [properties addEntriesFromDictionary:activity.userInfo];
        properties[@"url"] = activity.webpageURL;
        properties[@"title"] = activity.title ?: @"";
        [self track:@"Deep Link Opened" properties:[properties copy]];
    }
}

- (void)openURL:(NSURL *)url options:(NSDictionary *)options
{
    [self callIntegrationsWithSelector:_cmd arguments:@[ url, options ] options:nil sync:true];

    if (!self.configuration.trackDeepLinks) {
        return;
    }

    NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:options.count + 2];
    [properties addEntriesFromDictionary:options];
    properties[@"url"] = url.absoluteString;
    [self track:@"Deep Link Opened" properties:[properties copy]];
}

- (void)reset
{
    [self resetAnonymousId];
    [self callIntegrationsWithSelector:_cmd arguments:nil options:nil sync:false];
}

- (void)resetAnonymousId
{
    self.cachedAnonymousId = [self loadOrGenerateAnonymousID:YES];
}

- (NSString *)getAnonymousId;
{
    return self.cachedAnonymousId;
}

- (NSString *)loadOrGenerateAnonymousID:(BOOL)reset
{
#if TARGET_OS_TV
    NSString *anonymousId = [self.storage stringForKey:SEGAnonymousIdKey];
#else
    NSString *anonymousId = [self.storage stringForKey:kSEGAnonymousIdFilename];
#endif

    if (!anonymousId || reset) {
        // We've chosen to generate a UUID rather than use the UDID (deprecated in iOS 5),
        // identifierForVendor (iOS6 and later, can't be changed on logout),
        // or MAC address (blocked in iOS 7). For more info see https://segment.io/libraries/ios#ids
        anonymousId = GenerateUUIDString();
        SEGLog(@"New anonymousId: %@", anonymousId);
#if TARGET_OS_TV
        [self.storage setString:anonymousId forKey:SEGAnonymousIdKey];
#else
        [self.storage setString:anonymousId forKey:kSEGAnonymousIdFilename];
#endif
    }
    return anonymousId;
}

- (void)saveAnonymousId:(NSString *)anonymousId
{
    self.cachedAnonymousId = anonymousId;
#if TARGET_OS_TV
    [self.storage setString:anonymousId forKey:SEGAnonymousIdKey];
#else
    [self.storage setString:anonymousId forKey:@"segment.anonymousId"];
#endif
}

- (void)flush
{
    [self callIntegrationsWithSelector:_cmd arguments:nil options:nil sync:false];
}

- (void)enable
{
    _enabled = YES;
}

- (void)disable
{
    _enabled = NO;
}

#pragma mark - Analytics Settings

- (NSDictionary *)cachedSettings
{
    if (!_cachedSettings)
        _cachedSettings = [self.storage dictionaryForKey:@"analytics.settings.v2.plist"] ?: @{};
    return _cachedSettings;
}

- (void)setCachedSettings:(NSDictionary *)settings
{
    _cachedSettings = [settings copy];
    if (!_cachedSettings) {
        // [@{} writeToURL:settingsURL atomically:YES];
        return;
    }
    [self.storage setDictionary:_cachedSettings forKey:@"analytics.settings.v2.plist"];

    static dispatch_once_t once;
    dispatch_once(&once, ^{
        [self updateIntegrationsWithSettings:settings[@"integrations"]];
    });
}

- (void)updateIntegrationsWithSettings:(NSDictionary *)projectSettings
{
    for (id<SEGIntegrationFactory> factory in self.factories) {
        NSString *key = [factory key];
        NSDictionary *integrationSettings = [projectSettings objectForKey:key];
        if (integrationSettings) {
            id<SEGIntegration> integration = [factory createWithSettings:integrationSettings forAnalytics:self];
            if (integration != nil) {
                self.integrations[key] = integration;
                self.registeredIntegrations[key] = @NO;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:SEGAnalyticsIntegrationDidStart object:key userInfo:nil];
        } else {
            SEGLog(@"No settings for %@. Skipping.", key);
        }
    }

    seg_dispatch_specific_async(_serialQueue, ^{
        [self flushMessageQueue];
        self.initialized = true;
    });
}

- (void)refreshSettings
{
    if (self.settingsRequest) {
        return;
    }

    self.settingsRequest = [self.httpClient settingsForWriteKey:self.configuration.writeKey completionHandler:^(BOOL success, NSDictionary *settings) {
        if (success) {
            [self setCachedSettings:settings];
        }

        self.settingsRequest = nil;
    }];
}

#pragma mark - Class Methods

+ (instancetype)sharedAnalytics
{
    NSCAssert(__sharedInstance != nil, @"library must be initialized before calling this method.");
    return __sharedInstance;
}

+ (void)debug:(BOOL)showDebugLogs
{
    SEGSetShowDebugLogs(showDebugLogs);
}

+ (NSString *)version
{
    return @"3.5.0";
}

#pragma mark - Private

- (BOOL)isIntegration:(NSString *)key enabledInOptions:(NSDictionary *)options
{
    if ([@"Segment.io" isEqualToString:key]) {
        return YES;
    }
    if (options[key]) {
        return [options[key] boolValue];
    } else if (options[@"All"]) {
        return [options[@"All"] boolValue];
    } else if (options[@"all"]) {
        return [options[@"all"] boolValue];
    }
    return YES;
}

- (BOOL)isTrackEvent:(NSString *)event enabledForIntegration:(NSString *)key inPlan:(NSDictionary *)plan
{
    if (plan[@"track"][event]) {
        if ([plan[@"track"][event][@"enabled"] boolValue]) {
            return [self isIntegration:key enabledInOptions:plan[@"track"][event][@"integrations"]];
        } else {
            return NO;
        }
    }

    return YES;
}

- (void)forwardSelector:(SEL)selector arguments:(NSArray *)arguments options:(NSDictionary *)options
{
    if (!_enabled)
        return;

    // If the event has opted in for syncrhonous delivery, this may be called on any thread.
    // Only allow one to be delivered at a time.
    @synchronized(self)
    {
        [self.integrations enumerateKeysAndObjectsUsingBlock:^(NSString *key, id<SEGIntegration> integration, BOOL *stop) {
            [self invokeIntegration:integration key:key selector:selector arguments:arguments options:options];
        }];
    }
}

- (void)invokeIntegration:(id<SEGIntegration>)integration key:(NSString *)key selector:(SEL)selector arguments:(NSArray *)arguments options:(NSDictionary *)options
{
    if (![integration respondsToSelector:selector]) {
        SEGLog(@"Not sending call to %@ because it doesn't respond to %@.", key, NSStringFromSelector(selector));
        return;
    }

    if (![self isIntegration:key enabledInOptions:options[@"integrations"]]) {
        SEGLog(@"Not sending call to %@ because it is disabled in options.", key);
        return;
    }

    NSString *eventType = NSStringFromSelector(selector);
    if ([eventType hasPrefix:@"track:"]) {
        SEGTrackPayload *eventPayload = arguments[0];
        BOOL enabled = [self isTrackEvent:eventPayload.event enabledForIntegration:key inPlan:self.cachedSettings[@"plan"]];
        if (!enabled) {
            SEGLog(@"Not sending call to %@ because it is disabled in plan.", key);
            return;
        }
    }

    SEGLog(@"Running: %@ with arguments %@ on integration: %@", eventType, arguments, key);
    NSInvocation *invocation = [self invocationForSelector:selector arguments:arguments];
    [invocation invokeWithTarget:integration];
}

- (NSInvocation *)invocationForSelector:(SEL)selector arguments:(NSArray *)arguments
{
    struct objc_method_description description = protocol_getMethodDescription(@protocol(SEGIntegration), selector, NO, YES);

    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:description.types];

    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.selector = selector;
    for (int i = 0; i < arguments.count; i++) {
        id argument = (arguments[i] == [NSNull null]) ? nil : arguments[i];
        [invocation setArgument:&argument atIndex:i + 2];
    }
    return invocation;
}

- (void)queueSelector:(SEL)selector arguments:(NSArray *)arguments options:(NSDictionary *)options
{
    NSArray *obj = @[ NSStringFromSelector(selector), arguments ?: @[], options ?: @{} ];
    SEGLog(@"Queueing: %@", obj);
    [_messageQueue addObject:obj];
}

- (void)flushMessageQueue
{
    if (_messageQueue.count != 0) {
        for (NSArray *arr in _messageQueue)
            [self forwardSelector:NSSelectorFromString(arr[0]) arguments:arr[1] options:arr[2]];
        [_messageQueue removeAllObjects];
    }
}

- (void)callIntegrationsWithSelector:(SEL)selector arguments:(NSArray *)arguments options:(NSDictionary *)options sync:(BOOL)sync
{
    if (sync && self.initialized) {
        [self forwardSelector:selector arguments:arguments options:options];
        return;
    }

    seg_dispatch_specific_async(_serialQueue, ^{
        if (self.initialized) {
            [self flushMessageQueue];
            [self forwardSelector:selector arguments:arguments options:options];
        } else {
            [self queueSelector:selector arguments:arguments options:options];
        }
    });
}

- (NSDictionary *)bundledIntegrations
{
    return [self.registeredIntegrations copy];
}

@end


@implementation SEGAnalytics (Deprecated)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

+ (void)initializeWithWriteKey:(NSString *)writeKey
{
    [self setupWithConfiguration:[SEGAnalyticsConfiguration configurationWithWriteKey:writeKey]];
}

- (instancetype)initWithWriteKey:(NSString *)writeKey
{
    return [self initWithConfiguration:[SEGAnalyticsConfiguration configurationWithWriteKey:writeKey]];
}

- (void)registerPushDeviceToken:(NSData *)deviceToken
{
    [self registeredForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [self registeredForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken options:(NSDictionary *)options
{
    [self registeredForRemoteNotificationsWithDeviceToken:deviceToken];
}

#pragma clang diagnostic pop

@end
