// CrittercismIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import "SEGCrittercismIntegration.h"
#import <CrittercismSDK/Crittercism.h>
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"


@implementation SEGCrittercismIntegration

#pragma mark - Initialization

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:@"Crittercism"];
}

- (id)init
{
    if (self = [super init]) {
        self.name = @"Crittercism";
        self.valid = NO;
        self.initialized = NO;
        self.crittercismClass = [Crittercism class];
        self.crittercismConfigClass = [CrittercismConfig class];
    }
    return self;
}

- (void)start
{
    NSString *appId = [self.settings objectForKey:@"appId"];
    CrittercismConfig *config = [CrittercismConfig defaultConfig];
    [config setMonitorUIWebView:[(NSNumber *)[self.settings objectForKey:@"monitorWebView"] boolValue]];
    [self.crittercismClass enableWithAppID:appId andConfig:config];
    SEGLog(@"CrittercismIntegration initialized.");
    [super start];
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
        [self.crittercismClass setUsername:userId];
    }

    // Other traits. Iterate over all the traits and set them.
    for (NSString *key in traits) {
        [self.crittercismClass setValue:[traits objectForKey:key] forKey:key];
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [self.crittercismClass leaveBreadcrumb:event];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)optionsoptions
{
    [self.crittercismClass leaveBreadcrumb:SEGEventNameForScreenTitle(screenTitle)];
}


@end
