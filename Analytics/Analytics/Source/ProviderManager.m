// ProviderManager.m
// Copyright 2013 Segment.io

#import <UIKit/UIKit.h>

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
    traits = [ProviderManager coerceDictionary:traits];
    context = [ProviderManager coerceDictionary:context];
    
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
    properties = [ProviderManager coerceDictionary:properties];
    context = [ProviderManager coerceDictionary:context];
    
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
    properties = [ProviderManager coerceDictionary:properties];
    context = [ProviderManager coerceDictionary:context];
    
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

+ (NSDictionary *) coerceDictionary: (NSDictionary *) dict
{
    // make sure that a new dictionary exists even if the input is null
    NSDictionary * ensured = [NSDictionary dictionaryWithDictionary:dict];
    
    // assert that the proper types are in the dictionary
    [ProviderManager assertDictionaryTypes:ensured];
    
    // coerce urls, and dates to the proper format
    return [ProviderManager coerceJSONObject:ensured];
}

//
// Thanks to Mixpanel's iOS library for being the basis
// of this example.
//
// Mixpanel.m
// Mixpanel
//
// Copyright 2012 Mixpanel
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

+ (id)coerceJSONObject:(id)obj
{
    // if the object is a NSString, NSNumber or NSNull
    // then we're good
    if ([obj isKindOfClass:[NSString class]] ||
        [obj isKindOfClass:[NSNumber class]] ||
        [obj isKindOfClass:[NSNull class]]) {
        return obj;
    }
    
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *a = [NSMutableArray array];
        for (id i in obj) {
            [a addObject:[self coerceJSONObject:i]];
        }
        return [NSArray arrayWithArray:a];
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        for (id key in obj) {
            NSString *stringKey;
            if (![key isKindOfClass:[NSString class]]) {
                stringKey = [key description];
                NSLog(@"%@ warning: dictionary keys should be strings. got: %@. coercing to: %@", self, [key class], stringKey);
            } else {
                stringKey = [NSString stringWithString:key];
            }
            
            id v = [self coerceJSONObject:[obj objectForKey:key]];
            [d setObject:v forKey:stringKey];
        }
        return [NSDictionary dictionaryWithDictionary:d];
    }
    
    // check for NSDate
    if ([obj isKindOfClass:[NSDate class]]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        NSString *s = [formatter stringFromDate:obj];
        return s;
    }
    // and NSUrl
    else if ([obj isKindOfClass:[NSURL class]]) {
        return [obj absoluteString];
    }
    
    // default to sending the object's description
    NSString *desc = [obj description];
    NSLog(@"%@ warning: dictionary values should be valid json types. got: %@. coercing to: %@", self, [obj class], desc);
    return desc;
}

+ (void)assertDictionaryTypes:(NSDictionary *)dict
{
    for (id key in dict) {
        NSAssert([key isKindOfClass: [NSString class]], @"%@ dictionary key must be NSString. got: %@ %@", self, [key class], key);
        
        id value = [dict objectForKey:key];
        
        NSAssert([value isKindOfClass:[NSString class]] ||
                 [value isKindOfClass:[NSNumber class]] ||
                 [value isKindOfClass:[NSNull class]] ||
                 [value isKindOfClass:[NSArray class]] ||
                 [value isKindOfClass:[NSDictionary class]] ||
                 [value isKindOfClass:[NSDate class]] ||
                 [value isKindOfClass:[NSURL class]],
                 @"%@ Dictionary values must be NSString, NSNumber, NSNull, NSArray, NSDictionary, NSDate or NSURL. got: %@ %@", self, [[dict objectForKey:key] class], value);
    }
}

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
