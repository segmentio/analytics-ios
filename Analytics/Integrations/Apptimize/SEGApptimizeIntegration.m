//
//  SEGApptimizeIntegration.m
//  Analytics
//
//  Created by Dustin L. Howett on 3/30/15.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import "SEGApptimizeIntegration.h"

#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"

#import <Apptimize/Apptimize.h>
#import <Apptimize/Apptimize+Segment.h>


@implementation SEGApptimizeIntegration

+ (NSString *)name { return @"Apptimize"; }

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:[self name]];
}

- (id)init
{
    if (self = [super init]) {
        self.name = [[self class] name];
        self.valid = NO;
        self.initialized = NO;

        [Apptimize SEG_ensureLibraryHasBeenInitialized];
    }
    return self;
}

- (void)validate
{
    self.valid = [self.settings objectForKey:@"appkey"] != nil;
}

- (void)start
{
    [Apptimize startApptimizeWithApplicationKey:[self.settings objectForKey:@"appkey"]];

    if (![(NSNumber *)[self.settings objectForKey:@"listen"] boolValue]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(experimentDidGetViewed:)
                                                     name:ApptimizeTestRunNotification
                                                   object:nil];
    }

    [super start];
}

- (void)experimentDidGetViewed:(NSNotification *)notification
{
    if (!notification.userInfo[ApptimizeTestFirstRunUserInfoKey]) {
        return;
    }

    // Apptimize doesn't notify with IDs, so we iterate over all experiments to find the matching one.
    NSString *name = notification.userInfo[ApptimizeTestNameUserInfoKey];
    NSString *variant = notification.userInfo[ApptimizeVariantNameUserInfoKey];
    [[Apptimize testInfo] enumerateKeysAndObjectsUsingBlock:^(id key, id<ApptimizeTestInfo> experiment, BOOL *stop) {
      BOOL match = [experiment.testName isEqualToString:name] && [experiment.enrolledVariantName isEqualToString:variant];
      if (!match) {
          return;
      }
      [[SEGAnalytics sharedAnalytics] track:@"Experiment Viewed"
                                 properties:@{
                                     @"experimentId" : [experiment testID],
                                     @"experimentName" : [experiment testName],
                                     @"variationId" : [experiment enrolledVariantID],
                                     @"variationName" : [experiment enrolledVariantName]
                                 }];
      *stop = YES;
    }];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    if (userId != nil) {
        [Apptimize setUserAttributeString:userId forKey:@"user_id"];
    }

    if (traits) {
        [Apptimize SEG_setUserAttributesFromDictionary:traits];
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [Apptimize SEG_track:event attributes:properties];
}

- (void)reset
{
    [Apptimize SEG_resetUserData];
}

@end
