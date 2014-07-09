// CrittercismIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import "SEGCrittercismIntegration.h"
#import <Crittercism.h>
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"

@implementation SEGCrittercismIntegration

#pragma mark - Initialization

+ (void)load {
    [SEGAnalytics registerIntegration:self withIdentifier:@"Crittercism"];
}

- (id)init {
    if (self = [super init]) {
        self.name = @"Crittercism";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    NSString *appId = [self.settings objectForKey:@"appId"];
    [Crittercism enableWithAppID:appId];
    SEGLog(@"CrittercismIntegration initialized.");
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasAppId = [self.settings objectForKey:@"appId"] != nil;
    self.valid = hasAppId;
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    // Username
    if (userId) {
        [Crittercism setUsername:userId];
    }

    // Other traits. Iterate over all the traits and set them.
    for (NSString *key in traits) {
        [Crittercism setValue:[traits objectForKey:key] forKey:key];
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [Crittercism leaveBreadcrumb:event];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)optionsoptions
{
    [Crittercism leaveBreadcrumb:SEGEventNameForScreenTitle(screenTitle)];
}


@end
