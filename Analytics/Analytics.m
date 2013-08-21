// Analytics.m
// Copyright 2013 Segment.io

#import <UIKit/UIKit.h>
#import "AnalyticsUtils.h"
#import "AnalyticsProvider.h"
#import "AnalyticsRequest.h"
#import "Analytics.h"

#define SETTING_CACHE_URL AnalyticsURLForFilename(@"analytics.settings.plist")
static NSInteger const AnalyticsSettingsUpdateInterval = 3600;

@interface Analytics ()

@property (nonatomic, strong) NSArray *providers;
@property (nonatomic, strong) NSDictionary *cachedSettings;

@end

@implementation Analytics {
    dispatch_queue_t _serialQueue;
    NSMutableArray *_messageQueue;
    AnalyticsRequest *_settingsRequest;
    NSTimer *_settingsTimer;
}

@synthesize cachedSettings = _cachedSettings;

- (id)initWithSecret:(NSString *)secret {
    NSParameterAssert(secret.length);
    if (self = [self init]) {
        _secret = secret;
        _serialQueue = dispatch_queue_create("io.segment.analytics", DISPATCH_QUEUE_SERIAL);
        _messageQueue = [[NSMutableArray alloc] init];
        _providers = [[NSMutableArray alloc] init];
        for (Class providerClass in [[[self class] registeredProviders] allValues]) {
            [(NSMutableArray *)_providers addObject:[[providerClass alloc] initWithAnalytics:self]];
        }
        // Update settings on each provider immediately
        [self updateProvidersWithSettings:[self cachedSettings]];
        _settingsTimer = [NSTimer scheduledTimerWithTimeInterval:AnalyticsSettingsUpdateInterval
                                                          target:self
                                                        selector:@selector(refreshSettings)
                                                        userInfo:nil
                                                         repeats:YES];
        
        // Attach to application state change hooks
        for (NSString *name in @[UIApplicationDidEnterBackgroundNotification,
                                 UIApplicationWillEnterForegroundNotification,
                                 UIApplicationWillTerminateNotification,
                                 UIApplicationWillResignActiveNotification,
                                 UIApplicationDidBecomeActiveNotification]) {
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc addObserver:self selector:@selector(handleAppStateNotification:) name:name object:nil];
        }
    }
    return self;
}

- (BOOL)isProvider:(id<AnalyticsProvider>)provider enabledInContext:(NSDictionary *)context {
    // checks if context.providers is enabling this provider
    NSDictionary *providers = context[@"providers"];
    if (providers[provider.name]) {
        return [providers[provider.name] boolValue];
    } else if (providers[@"All"]) {
        return [providers[@"All"] boolValue];
    } else if (providers[@"all"]) {
        return [providers[@"all"] boolValue];
    }
    return YES;
}

- (void)forwardSelector:(SEL)selector arguments:(NSArray *)arguments context:(NSDictionary *)context {
    NSMethodSignature *methodSignature = [AnalyticsProvider instanceMethodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    invocation.selector = selector;
    for (int i=0; i<arguments.count; i++) {
        id argument = arguments[i];
        [invocation setArgument:&argument atIndex:i+2];
    }
    for (id<AnalyticsProvider> provider in self.providers) {
        if (provider.ready && [provider respondsToSelector:selector]
            && [self isProvider:provider enabledInContext:context]) {
            [invocation invokeWithTarget:provider];
        }
    }
}

- (void)queueSelector:(SEL)selector arguments:(NSArray *)arguments context:(NSDictionary *)context {
    [_messageQueue addObject:@[NSStringFromSelector(selector), arguments ?: @[], context ?: @{}]];
}

- (void)flushMessageQueue {
    if (_messageQueue.count) {
        for (NSArray *arr in _messageQueue)
            [self forwardSelector:NSSelectorFromString(arr[0]) arguments:arr[1] context:arr[2]];
        [_messageQueue removeAllObjects];
    }
}

- (void)callProvidersWithSelector:(SEL)selector arguments:(NSArray *)arguments context:(NSDictionary *)context  {
    dispatch_async(_serialQueue, ^{
        if (!self.cachedSettings.count) {
            [self queueSelector:selector arguments:arguments context:context];
        } else {
            [self flushMessageQueue];
            [self forwardSelector:selector arguments:arguments context:context];
        }
    });
}

#pragma mark - NSNotificationCenter Callback

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
        [self callProvidersWithSelector:selector arguments:nil context:nil];
}

#pragma mark - Public API

- (void)reset {
    [self setCachedSettings:nil];
    [self refreshSettings];
}

- (void)debug:(BOOL)showDebugLogs {
    SetShowDebugLogs(showDebugLogs);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<Analytics secret:%@>", self.secret];
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId {
    [self identify:userId traits:nil context:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits {
    [self identify:userId traits:traits context:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context {
    [self callProvidersWithSelector:_cmd
                          arguments:@[userId, CoerceDictionary(traits), CoerceDictionary(context)]
                            context:context];
}

- (void)track:(NSString *)event {
    [self track:event properties:nil context:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties {
    [self track:event properties:properties context:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context {
    [self callProvidersWithSelector:_cmd
                          arguments:@[event, CoerceDictionary(properties), CoerceDictionary(context)]
                            context:context];
}

- (void)screen:(NSString *)screenTitle {
    [self screen:screenTitle properties:nil context:nil];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties {
    [self screen:screenTitle properties:properties context:nil];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context {
    [self callProvidersWithSelector:_cmd
                          arguments:@[screenTitle, CoerceDictionary(properties), CoerceDictionary(context)]
                            context:context];
}

- (void)registerPushDeviceToken:(NSData *)deviceToken {
    NSParameterAssert(deviceToken);
    [self callProvidersWithSelector:_cmd
                          arguments:@[deviceToken]
                            context:nil];
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
    for (id<AnalyticsProvider> provider in self.providers)
        [provider updateSettings:settings[provider.name]];
    dispatch_async(_serialQueue, ^{
        [self flushMessageQueue];
    });
}

- (void)refreshSettings {
    if (!_settingsRequest) {
        NSString *urlString = [NSString stringWithFormat:@"http://api.segment.io/project/%@/settings", self.secret];
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
        [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [urlRequest setHTTPMethod:@"GET"];
        SOLog(@"%@ Sending API settings request: %@", self, urlRequest);
        
        _settingsRequest = [AnalyticsRequest startWithURLRequest:urlRequest completion:^{
            dispatch_async(_serialQueue, ^{
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
    NSAssert([NSThread isMainThread], @"%s must ce called fro main thread", __func__);
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

@end
