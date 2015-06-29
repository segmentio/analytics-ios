//
//  SEGTaplytics.m
//  Analytics
//
//  Created by Travis Jeffery on 6/4/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import "SEGTaplyticsIntegration.h"
#import "SEGAnalytics.h"
#import "SEGAnalyticsUtils.h"

#import <Taplytics/Taplytics.h>


@implementation SEGTaplyticsIntegration

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:[self identifier]];
}

- (id)init
{
    if (self = [super init]) {
        self.name = [self.class identifier];
        self.valid = NO;
        self.initialized = NO;
        self.taplyticsClass = [Taplytics class];
    }
    return self;
}

- (void)start
{
    NSDictionary *options = [[NSMutableDictionary alloc] init];
    [options setValue:[self delayLoad] forKey:@"delayLoad"];
    [options setValue:[self shakeMenu] forKey:@"shakeMenu"];
    [options setValue:[self pushSandbox] forKey:@"pushSandbox"];

    [self.taplyticsClass startTaplyticsAPIKey:[self apiKey] options:options];

    SEGLog(@"TaplyticsIntegration initialized with api key %@ and options %@", [self apiKey], options);
    [super start];
}

- (void)validate
{
    self.valid = ([self apiKey] != nil);
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    NSMutableDictionary *mappedTraits = [NSMutableDictionary dictionaryWithDictionary:traits];
    if (traits[@"avatar"]) {
        mappedTraits[@"avatarURL"] = traits[@"avatar"];
        [mappedTraits removeObjectForKey:@"avatar"];
    }
    mappedTraits[@"user_id"] = userId;

    [self.taplyticsClass setUserAttributes:mappedTraits];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    // If revenue is included, logRevenue to Taplytics.
    NSNumber *revenue = [SEGAnalyticsIntegration extractRevenue:properties];
    if (revenue) {
        [self.taplyticsClass logRevenue:event revenue:revenue metaData:properties];
    } else {
        [self.taplyticsClass logEvent:event value:nil metaData:properties];
    }
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    NSMutableDictionary *userAttributes = [[NSMutableDictionary alloc] init];

    if (groupId && [groupId length] > 0)
        [userAttributes setObject:groupId forKey:@"groupId"];

    if (traits && [[traits allKeys] count] > 0)
        [userAttributes setObject:traits forKey:@"groupTraits"];

    if (userAttributes.count > 0)
        [self.taplyticsClass setUserAttributes:userAttributes];
};

- (void)reset
{
    [self.taplyticsClass resetUser:^{
      SEGLog(@"Reset Taplytics User");
    }];
}

#pragma mark - Private

- (NSString *)apiKey
{
    return self.settings[@"apiKey"];
}

- (NSNumber *)delayLoad
{
    return (NSNumber *)[self.settings objectForKey:@"delayLoad"];
}

- (NSNumber *)shakeMenu
{
    return (NSNumber *)[self.settings objectForKey:@"shakeMenu"];
}

- (NSNumber *)pushSandbox
{
    return (NSNumber *)[self.settings objectForKey:@"pushSandbox"];
}

+ (NSString *)identifier
{
    return @"Taplytics";
}

@end
