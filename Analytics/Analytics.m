// Analytics.m
// Copyright 2013 Segment.io

#import <UIKit/UIKit.h>
#import "AnalyticsUtils.h"
#import "AnalyticsProvider.h"
#import "AnalyticsRequest.h"
#import "Analytics.h"

static NSString * const kAnalyticsSettings = @"kAnalyticsSettings";
static NSInteger const AnalyticsSettingsUpdateInterval = 3600;

@interface Analytics () <AnalyticsRequestDelegate>

@property(nonatomic, strong) NSArray *providers;
@property(nonatomic, strong) NSTimer *updateTimer;
@property(nonatomic, strong) AnalyticsRequest *request;

@end

@implementation Analytics {
    dispatch_queue_t _serialQueue;
}

- (id)initWithSecret:(NSString *)secret {
    NSParameterAssert(secret.length);
    
    if (self = [self init]) {
        _secret = secret;
        _serialQueue = dispatch_queue_create("io.segment.analytics", DISPATCH_QUEUE_SERIAL);
        _providers = [[NSMutableArray alloc] init];
        for (Class providerClass in [[[self class] registeredProviders] allValues]) {
            [(NSMutableArray *)_providers addObject:[[providerClass alloc] initWithAnalytics:self]];
        }
        // Update settings on each provider immediately
        [self updateProvidersWithSettings:[self localSettings]];
        _updateTimer = [NSTimer scheduledTimerWithTimeInterval:AnalyticsSettingsUpdateInterval
                                                        target:self
                                                      selector:@selector(requestSettingsFromNetwork)
                                                      userInfo:nil
                                                       repeats:YES];
        
        // Attach to application state change hooks
        for (NSString *name in @[UIApplicationDidEnterBackgroundNotification,
                                 UIApplicationWillEnterForegroundNotification,
                                 UIApplicationWillTerminateNotification,
                                 UIApplicationWillResignActiveNotification,
                                 UIApplicationDidBecomeActiveNotification]) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleAppStateNotification:)
                                                         name:name
                                                       object:nil];
        }
    }
    return self;
}

- (void)reset {
    [self requestSettingsFromNetwork];
}

- (void)debug:(BOOL)showDebugLogs {
    SetShowDebugLogs(showDebugLogs);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<Analytics secret:%@>", self.secret];
}

#pragma mark - Private Helpers

- (BOOL)isProvider:(AnalyticsProvider *)provider enabledInContext:(NSDictionary *)context {
    // checks if context.providers is enabling this provider
    
    if (!context) return YES;
    
    NSDictionary* providers = [context objectForKey:@"providers"];
    if (!providers) return YES;
    
    BOOL enabled = YES;
    // from: http://stackoverflow.com/questions/3822601/restoring-a-bool-inside-an-nsdictionary-from-a-plist-file
    if ([providers valueForKey:@"all"])
        enabled = [providers[@"all"] boolValue];
    if ([providers valueForKey:@"All"])
        enabled = [providers[@"All"] boolValue];
    
    if ([providers valueForKey:provider.name])
        enabled = [providers[provider.name] boolValue];
    
    return enabled;
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
    NSString *selectorName = selectorMapping[note.name];
    if (selectorName) {
        SEL selector = NSSelectorFromString(selectorName);
        for (AnalyticsProvider *provider in self.providers) {
            if (!provider.ready)
                continue;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [provider performSelector:selector];
#pragma clang diagnostic pop
        }
    }
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId {
    [self identify:userId traits:nil context:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits {
    [self identify:userId traits:traits context:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context {
    traits = CoerceDictionary(traits);
    context = CoerceDictionary(context);
    
    // Iterate over providersArray and call identify.
    for (id<AnalyticsProvider> provider in self.providers) {
        if ([provider ready] && [self isProvider:provider enabledInContext:context]) {
            [provider identify:userId traits:traits context:context];
        }
    }
}

- (void)track:(NSString *)event {
    [self track:event properties:nil context:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties {
    [self track:event properties:properties context:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context {
    properties = CoerceDictionary(properties);
    context = CoerceDictionary(context);
    
    // Iterate over providersArray and call track.
    for (id<AnalyticsProvider> provider in self.providers) {
        if ([provider ready] && [self isProvider:provider enabledInContext:context]) {
            [provider track:event properties:properties context:context];
        }
    }
}

- (void)screen:(NSString *)screenTitle {
    [self screen:screenTitle properties:nil context:nil];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties {
    [self screen:screenTitle properties:properties context:nil];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context {
    properties = CoerceDictionary(properties);
    context = CoerceDictionary(context);
    
    // Iterate over providersArray and call track.
    for (id<AnalyticsProvider> provider in self.providers) {
        if ([provider ready] && [self isProvider:provider enabledInContext:context]) {
            [provider screen:screenTitle properties:properties context:context];
        }
    }
}

#pragma mark - Settings

- (NSDictionary *)localSettings {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kAnalyticsSettings];
}

- (void)setLocalSettings:(NSDictionary *)settings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:settings forKey:kAnalyticsSettings];
    [self updateProvidersWithSettings:settings];
}

- (void)updateProvidersWithSettings:(NSDictionary *)settings {
    if (!settings)
        return;
    // Google Analytics needs to be initialized on the main thread, but
    // dispatch-ing to the main queue when already on the main thread
    // causes the initialization to happen async. After first startup
    // we need the initialization to be synchronous.
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(updateProvidersWithSettings:) withObject:settings waitUntilDone:NO];
        return;
    }
    for (AnalyticsProvider *provider in self.providers) {
        // Extract the settings for this provider and set them
        [provider updateSettings:settings[provider.name]];
    }
}

- (void)requestSettingsFromNetwork {
    if (!self.request) {
        NSString *urlString = [NSString stringWithFormat:@"http://api.segment.io/project/%@/settings", self.secret];
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
        [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [urlRequest setHTTPMethod:@"GET"];
        
        SOLog(@"%@ Sending API settings request: %@", self, urlRequest);
        
        self.request = [AnalyticsRequest startRequestWithURLRequest:urlRequest delegate:self];
    }
}

#pragma mark - AnalyticsJSONRequest Delegate

- (void)requestDidComplete:(AnalyticsRequest *)request {
    dispatch_async(_serialQueue, ^{
        if (!request.error) {
            [self setLocalSettings:request.responseJSON];
        }
        self.request = nil;
    });
}

#pragma mark - Class Methods

static Analytics *SharedInstance = nil;

+ (instancetype)withSecret:(NSString *)secret {
    NSParameterAssert(secret.length > 0);
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedInstance = [[self alloc] initWithSecret:secret];
    });
    return SharedInstance;
}

+ (instancetype)sharedAnalytics {
    NSAssert(SharedInstance, @"%@ sharedInstance called before withSecret", self);
    return SharedInstance;
}

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

@end
