// ProviderManager.m
// Copyright 2013 Segment.io

#import <UIKit/UIKit.h>

#import "SOUtils.h"
#import "ProviderManager.h"
#import "AnalyticsLogger.h"
#import "SettingsCache.h"
#import "Provider.h"
#import "SegmentioProvider.h"

#import "AmplitudeProvider.h"
#import "BugsnagProvider.h"
#import "ChartbeatProvider.h"
#import "CountlyProvider.h"
#import "FlurryProvider.h"
#import "GoogleAnalyticsProvider.h"
#import "KISSmetricsProvider.h"
#import "LocalyticsProvider.h"
#import "MixpanelProvider.h"

@interface ProviderManager () <SettingsCacheDelegate>

@property(nonatomic, strong) NSString *secret;
@property(nonatomic, strong) SettingsCache *settingsCache;
@property(nonatomic, strong) NSMutableArray *providersArray;

@end


@implementation ProviderManager {
    dispatch_queue_t _serialQueue;
}

#pragma mark - Initializiation

+ (instancetype)withSecret:(NSString *)secret
{
    return [[self alloc] initWithSecret:secret];
}

- (id)initWithSecret:(NSString *)secret
{
    if (self = [self init]) {
        _secret = secret;
        _providersArray = [NSMutableArray arrayWithCapacity:11];

        // Create each provider
        [_providersArray addObject:[SegmentioProvider withSecret:secret]];

        [_providersArray addObject:[AmplitudeProvider withNothing]];
        [_providersArray addObject:[BugsnagProvider withNothing]];
        [_providersArray addObject:[ChartbeatProvider withNothing]];
        [_providersArray addObject:[CountlyProvider withNothing]];
        [_providersArray addObject:[FlurryProvider withNothing]];
        [_providersArray addObject:[GoogleAnalyticsProvider withNothing]];
        [_providersArray addObject:[KISSmetricsProvider withNothing]];
        [_providersArray addObject:[LocalyticsProvider withNothing]];
        [_providersArray addObject:[MixpanelProvider withNothing]];
        
        // Create the settings cache last so that it can update settings
        // on each provider immediately if necessary
        _settingsCache = [SettingsCache withSecret:secret delegate:self];
        
        // Attach to application state change hooks
        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(applicationDidEnterBackground)
            name:UIApplicationDidEnterBackgroundNotification 
            object:NULL];
        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(applicationWillEnterForeground)
            name:UIApplicationWillEnterForegroundNotification 
            object:NULL];
        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(applicationWillTerminate)
            name:UIApplicationWillTerminateNotification 
            object:NULL];
        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(applicationWillResignActive)
            name:UIApplicationWillResignActiveNotification 
            object:NULL];
        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(applicationDidBecomeActive)
            name:UIApplicationDidBecomeActiveNotification 
            object:NULL];
    }
    return self;
}

#pragma mark - Provider Utils

- (NSDictionary *)augmentContext:(NSDictionary *)context
{
    NSMutableDictionary *augmentedContext = [NSMutableDictionary dictionaryWithDictionary:context];
    NSMutableDictionary *providers = [NSMutableDictionary dictionaryWithDictionary:[augmentedContext objectForKey:@"providers"]];
    
    // Iterate over providersArray
    for (id object in self.providersArray) {
        Provider *provider = (Provider *)object;
        if (![provider.name isEqualToString:@"Segment.io"]) {
            [providers setValue:@NO forKey:provider.name];
        }
    }
    
    [augmentedContext setValue:providers forKey:@"providers"];
    return augmentedContext;
}

- (BOOL) isEnabled:(NSDictionary *)context provider:(Provider *)provider
{
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




#pragma mark - Analytics API


- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context
{
    traits = CoerceDictionary(traits);
    context = CoerceDictionary(context);
    
    // Iterate over providersArray and call identify.
    for (id object in self.providersArray) {
        Provider *provider = (Provider *)object;
        if ([provider ready] && [self isEnabled:context provider:provider]) {
            if ([provider.name isEqualToString:@"Segment.io"]) {
                // Segment.io provider gets an augmented context to prevent server-side firing
                NSDictionary *augmentedContext = [self augmentContext:context];
                [provider identify:userId traits:traits context:augmentedContext];
            } else {
                [provider identify:userId traits:traits context:context];
            }
        }
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    properties = CoerceDictionary(properties);
    context = CoerceDictionary(context);
    
    // Iterate over providersArray and call track.
    for (id object in self.providersArray) {
        Provider *provider = (Provider *)object;
        if ([provider ready] && [self isEnabled:context provider:provider]) {
            if ([provider.name isEqualToString:@"Segment.io"]) {
                // Segment.io provider gets an augmented context to prevent server-side firing
                NSDictionary *augmentedContext = [self augmentContext:context];
                [provider track:event properties:properties context:augmentedContext];
            } else {
                [provider track:event properties:properties context:context];
            }
        }
    }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    properties = CoerceDictionary(properties);
    context = CoerceDictionary(context);
    
    // Iterate over providersArray and call track.
    for (id object in self.providersArray) {
        Provider *provider = (Provider *)object;
        if ([provider ready] && [self isEnabled:context provider:provider]) {
            if ([provider.name isEqualToString:@"Segment.io"]) {
                // Segment.io provider gets an augmented context to prevent server-side firing
                NSDictionary *augmentedContext = [self augmentContext:context];
                [provider screen:screenTitle properties:properties context:augmentedContext];
            } else {
                [provider screen:screenTitle properties:properties context:context];
            }
        }
    }
}


#pragma mark - Analytics App Events Forwarding

- (void)forwardSelectorToProviders:(SEL)selector {
    for (Provider *provider in self.providersArray) {
        if (provider.ready) {
            [provider performSelector:selector];
        }
    }
}

- (void)applicationDidEnterBackground {
    [AnalyticsLogger log:@"Application state change notification: applicationDidEnterBackground"];
    [self forwardSelectorToProviders:@selector(applicationDidEnterBackground)];
}

- (void)applicationWillEnterForeground {
    [AnalyticsLogger log:@"Application state change notification: applicationWillEnterForeground"];
    [self forwardSelectorToProviders:@selector(applicationWillEnterForeground)];
}

- (void)applicationWillTerminate {
    [AnalyticsLogger log:@"Application state change notification: applicationWillTerminate"];
    [self forwardSelectorToProviders:@selector(applicationWillTerminate)];
}

- (void)applicationWillResignActive {
    [AnalyticsLogger log:@"Application state change notification: applicationWillResignActive"];
    [self forwardSelectorToProviders:@selector(applicationWillResignActive)];
}

- (void)applicationDidBecomeActive {
    [AnalyticsLogger log:@"Application state change notification: applicationDidBecomeActive"];
    [self forwardSelectorToProviders:@selector(applicationDidBecomeActive)];
}


#pragma mark - NSObject

- (void)reset {
    [self.settingsCache update];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<Analytics ProviderManager(%p) Secret: %@>", self, self.secret];
}

#pragma mark JSON Utilities


#pragma mark - SettingsCacheDelegate

- (void)onSettingsUpdate:(NSDictionary *)settings
{
    // Iterate over providersArray
    for (Provider *provider in self.providersArray) {
        if (![provider.name isEqualToString:@"Segment.io"]) {
            // Extract the settings for this provider and set them
            NSDictionary *providerSettings = settings[provider.name];
            
            // Google Analytics needs to be initialized on the main thread, but
            // dispatch-ing to the main queue when already on the main thread
            // causes the initialization to happen async. After first startup
            // we need the initialization to be synchronous.
            if ([NSThread isMainThread]) {
                [provider updateSettings:providerSettings];
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [provider updateSettings:providerSettings];
                });
            }
        }
    }
}

@end
