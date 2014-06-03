// Analytics.m
// Copyright 2013 Segment.io

#import <UIKit/UIKit.h>
#import "AnalyticsUtils.h"
#import "AnalyticsProvider.h"
#import "AnalyticsRequest.h"
#import "Analytics.h"

#define SETTING_CACHE_URL AnalyticsURLForFilename(@"analytics.settings.plist")

@interface Analytics ()

@property (nonatomic, strong) NSDictionary *providers;
@property (nonatomic, strong) NSDictionary *cachedSettings;

@end

@implementation Analytics {
    dispatch_queue_t _serialQueue;
    NSMutableArray *_messageQueue;
    AnalyticsRequest *_settingsRequest;
    BOOL _enabled;
}

@synthesize cachedSettings = _cachedSettings;

- (id)initWithSecret:(NSString *)secret {
    NSParameterAssert(secret.length);
    if (self = [self init]) {
        _secret = secret;
        _enabled = YES;
        _serialQueue = so_dispatch_queue_create_specific("io.segment.analytics", DISPATCH_QUEUE_SERIAL);
        _messageQueue = [[NSMutableArray alloc] init];
        _providers = [[NSMutableDictionary alloc] init];
        [[[self class] registeredProviders] enumerateKeysAndObjectsUsingBlock:
                ^(NSString *identifier, Class providerClass, BOOL *stop) {
             ((NSMutableDictionary *)_providers)[identifier] = [[providerClass alloc] initWithAnalytics:self];
        }];
        
        // Update settings on each provider immediately
        [self refreshSettings];
        
        // Attach to application state change hooks
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        
        // Update settings on foreground
        [nc addObserver:self selector:@selector(onAppForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        // Pass through for application state change events
        for (NSString *name in @[UIApplicationDidEnterBackgroundNotification,
                                 UIApplicationWillEnterForegroundNotification,
                                 UIApplicationWillTerminateNotification,
                                 UIApplicationWillResignActiveNotification,
                                 UIApplicationDidBecomeActiveNotification]) {
            [nc addObserver:self selector:@selector(handleAppStateNotification:) name:name object:nil];
        }
    }
    return self;
}

- (BOOL)isProvider:(id<AnalyticsProvider>)provider enabledInOptions:(NSDictionary *)options {
    // checks if options.providers is enabling this provider
    NSDictionary *providers = options[@"providers"];
    if (providers[provider.name]) {
        return [providers[provider.name] boolValue];
    } else if (providers[@"All"]) {
        return [providers[@"All"] boolValue];
    } else if (providers[@"all"]) {
        return [providers[@"all"] boolValue];
    }
    return YES;
}

- (void)forwardSelector:(SEL)selector arguments:(NSArray *)arguments options:(NSDictionary *)options {
    if (!_enabled) {
        return;
    }
    
    NSMethodSignature *methodSignature = [AnalyticsProvider instanceMethodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    invocation.selector = selector;
    for (int i=0; i<arguments.count; i++) {
        id argument = (arguments[i] == [NSNull null]) ? nil : arguments[i];
        [invocation setArgument:&argument atIndex:i+2];
    }
    
    for (id<AnalyticsProvider> provider in self.providers.allValues) {
        if (provider.ready && [provider respondsToSelector:selector]) {
            if([self isProvider:provider enabledInOptions:options]) {
                [invocation invokeWithTarget:provider];
            }
            else {
                SOLog(@"Not sending call to %@ because it is disabled in options.providers", provider.name);
            }
        }
    }
}

- (void)queueSelector:(SEL)selector arguments:(NSArray *)arguments options:(NSDictionary *)options {
    [_messageQueue addObject:@[NSStringFromSelector(selector), arguments ?: @[], options ?: @{}]];
}

- (void)flushMessageQueue {
    if (_messageQueue.count) {
        for (NSArray *arr in _messageQueue)
            [self forwardSelector:NSSelectorFromString(arr[0]) arguments:arr[1] options:arr[2]];
        [_messageQueue removeAllObjects];
    }
}

- (void)callProvidersWithSelector:(SEL)selector arguments:(NSArray *)arguments options:(NSDictionary *)options  {
    so_dispatch_specific_async(_serialQueue, ^{
        // No cached settings, queue the API call
        if (!self.cachedSettings.count) {
            [self queueSelector:selector arguments:arguments options:options];
        }
        // Settings cached, flush message queue & new API call
        else {
            [self flushMessageQueue];
            [self forwardSelector:selector arguments:arguments options:options];
        }
    });
}

#pragma mark - NSNotificationCenter Callback


- (void)onAppForeground:(NSNotification *)note {
    [self refreshSettings];
}

- (void)handleAppStateNotification:(NSNotification *)note {
    SOLog(@"Application state change notification: %@", note.name);
    static NSDictionary *selectorMapping;
    static dispatch_once_t selectorMappingOnce;
    dispatch_once(&selectorMappingOnce, ^{
        selectorMapping = @{
            UIApplicationDidEnterBackgroundNotification:
                NSStringFromSelector(@selector(applicationDidEnterBackground)),
            UIApplicationWillEnterForegroundNotification:
                NSStringFromSelector(@selector(applicationWillEnterForeground)),
            UIApplicationWillTerminateNotification:
                NSStringFromSelector(@selector(applicationWillTerminate)),
            UIApplicationWillResignActiveNotification:
                NSStringFromSelector(@selector(applicationWillResignActive)),
            UIApplicationDidBecomeActiveNotification:
                NSStringFromSelector(@selector(applicationDidBecomeActive))
        };
    });
    SEL selector = NSSelectorFromString(selectorMapping[note.name]);
    if (selector)
        [self callProvidersWithSelector:selector arguments:nil options:nil];
}

#pragma mark - Public API

- (NSString *)description {
    return [NSString stringWithFormat:@"<Analytics secret:%@>", self.secret];
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId {
    [self identify:userId traits:nil options:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits {
    [self identify:userId traits:traits options:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {
    [self callProvidersWithSelector:_cmd
                          arguments:@[userId ?: [NSNull null], CoerceDictionary(traits), CoerceDictionary(options)]
                            options:options];
}

- (void)track:(NSString *)event {
    [self track:event properties:nil options:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties {
    [self track:event properties:properties options:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
    NSParameterAssert(event);
    [self callProvidersWithSelector:_cmd
                          arguments:@[event, CoerceDictionary(properties), CoerceDictionary(options)]
                            options:options];
}

- (void)screen:(NSString *)screenTitle {
    [self screen:screenTitle properties:nil options:nil];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties {
    [self screen:screenTitle properties:properties options:nil];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options {
    NSParameterAssert(screenTitle);
    [self callProvidersWithSelector:_cmd
                          arguments:@[screenTitle, CoerceDictionary(properties), CoerceDictionary(options)]
                            options:options];
}

- (void)registerPushDeviceToken:(NSData *)deviceToken {
    NSParameterAssert(deviceToken);
    [self callProvidersWithSelector:_cmd
                          arguments:@[deviceToken]
                            options:nil];
}

- (void)reset {
    [self callProvidersWithSelector:_cmd
                          arguments:nil
                            options:nil];
}

- (void)enable {
    _enabled = YES;
}

- (void)disable {
    _enabled = NO;
}

#pragma mark - Analytics Settings

- (NSDictionary *)cachedSettings {
    if (!_cachedSettings)
        _cachedSettings = [NSDictionary dictionaryWithContentsOfURL:SETTING_CACHE_URL] ?: @{};
    return _cachedSettings;
}

- (void)setCachedSettings:(NSDictionary *)settings {
    _cachedSettings = settings;
    [_cachedSettings ?: @{} writeToURL:SETTING_CACHE_URL atomically:YES];
    [self updateProvidersWithSettings:settings];
}

- (void)updateProvidersWithSettings:(NSDictionary *)settings {
    for (id<AnalyticsProvider> provider in self.providers.allValues)
        [provider updateSettings:settings[provider.name]];
    so_dispatch_specific_async(_serialQueue, ^{
        [self flushMessageQueue];
    });
}

- (void)refreshSettings {
    if (self.cachedSettings) {
        [self updateProvidersWithSettings:self.cachedSettings];
    }
    if (!_settingsRequest) {
        NSString *urlString = [NSString stringWithFormat:@"https://api.segment.io/project/%@/settings", self.secret];
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
        [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [urlRequest setHTTPMethod:@"GET"];
        SOLog(@"%@ Sending API settings request: %@", self, urlRequest);
        
        _settingsRequest = [AnalyticsRequest startWithURLRequest:urlRequest completion:^{
            so_dispatch_specific_async(_serialQueue, ^{
                SOLog(@"%@ Received API settings response: %@", self, _settingsRequest.responseJSON);
                if (!_settingsRequest.error) {
                    [self setCachedSettings:_settingsRequest.responseJSON];
                }
                _settingsRequest = nil;
            });
        }];
    }
}

#pragma mark - Class Methods

static NSMutableDictionary *RegisteredProviders = nil;

+ (NSDictionary *)registeredProviders { return [RegisteredProviders copy]; }

+ (void)registerProvider:(Class)providerClass withIdentifier:(NSString *)identifer {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        RegisteredProviders = [[NSMutableDictionary alloc] init];
    });
    NSAssert([NSThread isMainThread], @"%s must be called from the main thread", __func__);
    NSAssert(SharedInstance == nil, @"%s can only be called before Analytics initialization", __func__);
    NSAssert(identifer.length > 0, @"Provider must have a valid identifier;");
    RegisteredProviders[identifer] = providerClass;
}

static Analytics *SharedInstance = nil;

+ (void)initializeWithSecret:(NSString *)secret {
    NSParameterAssert(secret.length > 0);
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedInstance = [[self alloc] initWithSecret:secret];
    });
}

+ (instancetype)sharedAnalytics {
    NSAssert(SharedInstance, @"%@ sharedInstance called before withSecret", self);
    return SharedInstance;
}

+ (void)debug:(BOOL)showDebugLogs {
    SetShowDebugLogs(showDebugLogs);
}

+ (NSString *)version {
    return NSStringize(ANALYTICS_VERSION);
}

@end
