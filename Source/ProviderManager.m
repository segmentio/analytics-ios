// ProviderManager.m
// Copyright 2013 Segment.io

#import "ProviderManager.h"

#import "SettingsCache.h"

#import "Provider.h"
#import "GoogleAnalyticsProvider.h"
#import "SegmentioProvider.h"
#import "MixpanelProvider.h"
#import "GoogleAnalyticsProvider.h"

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
        _settingsCache = [SettingsCache withSecret:secret delegate:self];
        _providersArray = [NSMutableArray arrayWithCapacity:3];

        // Create each provider
        [_providersArray addObject:[SegmentioProvider withSecret:secret]];
        [_providersArray addObject:[MixpanelProvider withNothing]];
        [_providersArray addObject:[GoogleAnalyticsProvider withNothing]];
    }
    return self;
}


#pragma mark - Settings

- (void)onSettingsUpdate:(NSDictionary *)settings
{
    // Iterate over providersArray
    for (id object in self.providersArray) {
        Provider *provider = (Provider *)object;
        if (![provider.name isEqualToString:@"Segmentio"]) {
            // Extract the settings for this provider and set them
            NSDictionary *providerSettings = [settings objectForKey:provider.name];
            dispatch_async(dispatch_get_main_queue(), ^{
                [provider updateSettings:providerSettings];
            });
        }
    }
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context
{
    // Iterate over providersArray and call identify.
    for (id object in self.providersArray) {
        Provider *provider = (Provider *)object;
        if ([provider ready]) {
            [provider identify:userId traits:traits context:context];
        }
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    // Iterate over providersArray and call track.
    for (id object in self.providersArray) {
        Provider *provider = (Provider *)object;
        if ([provider ready]) {
            [provider track:event properties:properties context:context];
        }
    }
}

- (void)alias:(NSString *)from to:(NSString *)to context:(NSDictionary *)context
{
    // Iterate over providersArray and call alias.
    for (id object in self.providersArray) {
        Provider *provider = (Provider *)object;
        if ([provider ready]) {
            [provider alias:from to:to context:context];
        }
    }
}



#pragma mark - NSObject

- (NSString *)description
{
    return @"<Analytics ProviderManager>";
}

@end
