// Analytics.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <UIKit/UIKit.h>
#import "AnalyticsUtils.h"
#import "AnalyticsIntegration.h"
#import "AnalyticsRequest.h"
#import "Analytics.h"
#import "AnalyticsIntegrations.h"

#define SETTING_CACHE_URL AnalyticsURLForFilename(@"analytics.settings.plist")

@interface Analytics ()

@property (nonatomic, strong) NSDictionary *cachedSettings;

@end

@implementation Analytics {
    dispatch_queue_t _serialQueue;
    NSMutableArray *_messageQueue;
    AnalyticsRequest *_settingsRequest;
    BOOL _enabled;
    NSMutableDictionary *_integrations;
}

@synthesize cachedSettings = _cachedSettings;

- (id)initWithWriteKey:(NSString *)writeKey {
    NSParameterAssert(writeKey.length);
    
    if (self = [self init]) {
        _writeKey = [writeKey copy];
        _enabled = YES;
        _serialQueue = dispatch_queue_create_specific("io.segment.analytics", DISPATCH_QUEUE_SERIAL);
        _messageQueue = [[NSMutableArray alloc] init];
        _integrations = [[NSMutableDictionary alloc] init];
        
        [[[self class] registeredIntegrations] enumerateKeysAndObjectsUsingBlock:
                ^(NSString *identifier, Class integrationClass, BOOL *stop) {
             _integrations[identifier] = [[integrationClass alloc] initWithAnalytics:self];
        }];

        // Update settings on each integration immediately
        [self refreshSettings];

        // Attach to application state change hooks
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

        // Update settings on foreground
        [nc addObserver:self selector:@selector(onAppForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

        // Pass through for application state change events
        for (NSString *name in @[UIApplicationDidEnterBackgroundNotification,
                                 UIApplicationDidFinishLaunchingNotification,
                                 UIApplicationWillEnterForegroundNotification,
                                 UIApplicationWillTerminateNotification,
                                 UIApplicationWillResignActiveNotification,
                                 UIApplicationDidBecomeActiveNotification]) {
            [nc addObserver:self selector:@selector(handleAppStateNotification:) name:name object:nil];
        }
    }
    return self;
}

- (BOOL)isIntegration:(id<AnalyticsIntegration>)integration enabledInOptions:(NSDictionary *)options {
    // checks if options is enabling this integration
    if (options[integration.name]) {
        return [options[integration.name] boolValue];
    } else if (options[@"All"]) {
        return [options[@"All"] boolValue];
    } else if (options[@"all"]) {
        return [options[@"all"] boolValue];
    }
    return YES;
}

- (void)forwardSelector:(SEL)selector arguments:(NSArray *)arguments options:(NSDictionary *)options {
    if (!_enabled) {
        return;
    }

    NSMethodSignature *methodSignature = [AnalyticsIntegration instanceMethodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    invocation.selector = selector;
    for (int i=0; i<arguments.count; i++) {
        id argument = (arguments[i] == [NSNull null]) ? nil : arguments[i];
        [invocation setArgument:&argument atIndex:i+2];
    }

    for (id<AnalyticsIntegration> integration in self.integrations.allValues) {
        
        if (integration.ready) {
            if ([integration respondsToSelector:selector]) {
                if([self isIntegration:integration enabledInOptions:options]) {
                    [invocation invokeWithTarget:integration];
                }
                else {
                    SOLog(@"Not sending call to %@ because it is disabled in options.", integration.name);
                }
            }
            else {
                SOLog(@"Not sending call to %@ because it doesn't respond to %@.", integration.name, selector);
            }
        }
        else {
            SOLog(@"Not sending call to %@ because it isn't ready (enabled and initialized).", integration.name);
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

- (void)callIntegrationsWithSelector:(SEL)selector arguments:(NSArray *)arguments options:(NSDictionary *)options  {
    dispatch_specific_async(_serialQueue, ^{
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
            UIApplicationDidFinishLaunchingNotification:
                NSStringFromSelector(@selector(applicationDidFinishLaunching)),
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
        [self callIntegrationsWithSelector:selector arguments:nil options:nil];
}

#pragma mark - Public API

- (NSString *)description {
    return [NSString stringWithFormat:@"<Analytics writeKey:%@>", self.writeKey];
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId {
    [self identify:userId traits:nil options:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits {
    [self identify:userId traits:traits options:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {
    if (!userId && !traits)
        return;
    [self callIntegrationsWithSelector:_cmd
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
    [self callIntegrationsWithSelector:_cmd
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
    [self callIntegrationsWithSelector:_cmd
                          arguments:@[[NSString stringWithFormat:@"Viewed %@ Screen", screenTitle], CoerceDictionary(properties), CoerceDictionary(options)]
                            options:options];
}

- (void)group:(NSString *)groupId {
    [self group:groupId traits:nil options:nil];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits {
    [self group:groupId traits:traits options:nil];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options {
    [self callIntegrationsWithSelector:_cmd
                          arguments:@[groupId ?: [NSNull null], CoerceDictionary(traits), CoerceDictionary(options)]
                            options:options];
}

- (void)registerPushDeviceToken:(NSData *)deviceToken {
    NSParameterAssert(deviceToken);
    [self callIntegrationsWithSelector:_cmd
                          arguments:@[deviceToken]
                            options:nil];
}

- (void)reset {
    [self callIntegrationsWithSelector:_cmd
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
    _cachedSettings = [settings copy];
    [_cachedSettings ?: @{} writeToURL:SETTING_CACHE_URL atomically:YES];
    [self updateIntegrationsWithSettings:settings];
}

- (void)updateIntegrationsWithSettings:(NSDictionary *)settings {
    
    for (id<AnalyticsIntegration> integration in self.integrations.allValues)
        [integration updateSettings:settings[integration.name]];
    dispatch_specific_async(_serialQueue, ^{
        [self flushMessageQueue];
    });
}

- (void)refreshSettings {
    if (!_settingsRequest) {
        NSString *urlString = [NSString stringWithFormat:@"https://api.segment.io/project/%@/settings", self.writeKey];
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
        [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [urlRequest setHTTPMethod:@"GET"];
        SOLog(@"%@ Sending API settings request: %@", self, urlRequest);

        _settingsRequest = [AnalyticsRequest startWithURLRequest:urlRequest completion:^{
            dispatch_specific_async(_serialQueue, ^{
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

static NSMutableDictionary *__registeredIntegrations = nil;

+ (NSDictionary *)registeredIntegrations {
    return [__registeredIntegrations copy];
}

+ (void)registerIntegration:(Class)integrationClass withIdentifier:(NSString *)identifer {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __registeredIntegrations = [[NSMutableDictionary alloc] init];
    });
    NSAssert([NSThread isMainThread], @"%s must be called from the main thread", __func__);
    NSAssert(__sharedInstance == nil, @"%s can only be called before Analytics initialization", __func__);
    NSAssert(identifer.length > 0, @"Integration must have a valid identifier;");
    __registeredIntegrations[identifer] = integrationClass;
}

static Analytics *__sharedInstance = nil;

+ (void)initializeWithWriteKey:(NSString *)writeKey {
    NSParameterAssert(writeKey.length > 0);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[self alloc] initWithWriteKey:writeKey];
    });
}

+ (instancetype)sharedAnalytics {
    NSAssert(__sharedInstance, @"%@ sharedInstance called before initWithWriteKey", self);
    return __sharedInstance;
}

+ (void)debug:(BOOL)showDebugLogs {
    SetShowDebugLogs(showDebugLogs);
}

+ (NSString *)version {
    return NSStringize(ANALYTICS_VERSION);
}

@end
