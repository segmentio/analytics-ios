// Analytics.m
// Copyright 2013 Segment.io

#import "Analytics.h"

#define ANALYTICS_VERSION @"0.2.2"


@implementation Analytics {
    dispatch_queue_t _serialQueue;
}

static Analytics *sharedAnalytics = nil;



#pragma mark - Initializiation

+ (instancetype)sharedAnalyticsWithSecret:(NSString *)secret
{
    return [self sharedAnalyticsWithSecret:secret];
}

+ (instancetype)sharedAnalytics
{
    NSAssert(sharedAnalytics, @"%@ sharedAnalytics called before sharedAnalyticsWithSecret", self);
    return sharedAnalytics;
}

- (id)initWithSecret:(NSString *)secret
{
    NSParameterAssert(secret.length);
    
    if (self = [self init]) {
        _secret = secret;
        _providerManager = [ProviderManager withSecret:secret];
    }
    return self;
}



#pragma mark - Analytics API


- (void)identify:(NSString *)userId
{
    [self identify:userId traits:nil context:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits
{
    [self identify:userId traits:traits context:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context
{
    [self.providerManager identify:userId traits:traits context:context];
}


- (void)track:(NSString *)event
{
    [self track:event properties:nil context:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties
{
    [self track:event properties:properties context:nil];
}

 - (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    NSAssert(event.length, @"%@ track requires an event name.", self);

    [self.providerManager track:event properties:properties context:context];
}


- (void)alias:(NSString *)from to:(NSString *)to
{
    [self alias:from to:to context:nil];
}

- (void)alias:(NSString *)from to:(NSString *)to context:(NSDictionary *)context
{
    NSAssert(from.length, @"%@ alias requires a from id.", self);
    NSAssert(to.length, @"%@ alias requires a to id.", self);
    
    [self.providerManager  alias:from to:to context:context];
}

#pragma mark - NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<Analytics secret:%@>", self.secret];
}

@end
