// ProviderManager.m
// Copyright 2013 Segment.io

#import "ProviderManager.h"
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

#ifdef DEBUG
#define AnalyticsDebugLog(...) NSLog(__VA_ARGS__)
#else
#define AnalyticsDebugLog(...)
#endif

@interface ProviderManager ()

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
        _settingsCache = [SettingsCache withSecret:secret delegate:(SettingsCacheDelegate *)self];
    }
    return self;
}


#pragma mark - Settings

- (void)onSettingsUpdate:(NSDictionary *)settings
{
    // Iterate over providersArray
    for (id object in self.providersArray) {
        Provider *provider = (Provider *)object;
        if (![provider.name isEqualToString:@"Segment.io"]) {
            // Extract the settings for this provider and set them
            NSDictionary *providerSettings = [settings objectForKey:provider.name];

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
    if ([providers valueForKey:@"all"]) enabled = [[providers valueForKey:@"all"] boolValue];
    if ([providers valueForKey:@"All"]) enabled = [[providers valueForKey:@"All"] boolValue];
    
    if ([providers valueForKey:provider.name]) enabled = [[providers valueForKey:provider.name] boolValue];

    
    return enabled;
}

#pragma mark - Analytics API


- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context
{
    context = [NSMutableDictionary dictionaryWithDictionary:context];
    
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
    context = [NSMutableDictionary dictionaryWithDictionary:context];
    
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
    context = [NSMutableDictionary dictionaryWithDictionary:context];
    
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



#pragma mark - Analytics API

- (void)applicationDidEnterBackground
{
    // Iterate over providersArray and call track.
    for (id object in self.providersArray) {
        Provider *provider = (Provider *)object;
        if ([provider ready]) {
            [provider applicationDidEnterBackground];
        }
    }
}

- (void)applicationWillEnterForeground
{
    // Iterate over providersArray and call track.
    for (id object in self.providersArray) {
        Provider *provider = (Provider *)object;
        if ([provider ready]) {
            [provider applicationWillEnterForeground];
        }
    }
}

- (void)applicationWillTerminate
{
    // Iterate over providersArray and call track.
    for (id object in self.providersArray) {
        Provider *provider = (Provider *)object;
        if ([provider ready]) {
            [provider applicationWillTerminate];
        }
    }
}

- (void)applicationWillResignActive
{
    // Iterate over providersArray and call track.
    for (id object in self.providersArray) {
        Provider *provider = (Provider *)object;
        if ([provider ready]) {
            [provider applicationWillResignActive];
        }
    }
}

- (void)applicationDidBecomeActive
{
    // Iterate over providersArray and call track.
    for (id object in self.providersArray) {
        Provider *provider = (Provider *)object;
        if ([provider ready]) {
            [provider applicationDidBecomeActive];
        }
    }
}



#pragma mark - NSObject

- (void)reset
{
    [self.settingsCache update];
}


- (NSString *)description
{
    return @"<Analytics ProviderManager>";
}

@end
