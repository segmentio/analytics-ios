// ProviderManager.m
// Copyright 2013 Segment.io

#import "ProviderManager.h"

#import "SettingsCache.h"

@interface ProviderManager ()

@property(nonatomic, strong) NSString *secret;
@property(nonatomic, strong) SettingsCache *settingsCache;
@property(nonatomic, strong) NSArray *providersArray;

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
    }
    return self;
}


#pragma mark - Settings

- (void)onSettingsUpdate:(NSDictionary *)settings
{
    // TODO iterate over providersArray, update settings for each provider
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits
{
    // TODO iterate over providersArray and call identify
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties
{
    // TODO iterate over providersArray and call track
}

- (void)alias:(NSString *)from to:(NSString *)to
{
    // TODO iterate over providersArray and call alias
}



#pragma mark - NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<Analytics ProviderManager:%@>", self.settings];
}

@end
