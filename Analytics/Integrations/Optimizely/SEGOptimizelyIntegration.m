//
//  SEGOptmizelyIntegration.m
//  Analytics
//
//  Created by Travis Jeffery on 7/16/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import "SEGOptimizelyIntegration.h"
#import "SEGAnalytics.h"
#import "SEGAnalyticsUtils.h"
#import <Optimizely/Optimizely.h>

NSString *SEGMixpanelClass = @"Mixpanel";


@implementation SEGOptimizelyIntegration

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:self.identifier];
}

- (id)init
{
    if (self = [super init]) {
        self.name = self.class.identifier;
        self.valid = YES;
        self.initialized = NO;
        self.optimizelyClass = [Optimizely class];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(integrationDidStart:) name:SEGAnalyticsIntegrationDidStart object:nil];
    }
    return self;
}

- (void)start
{
    [self activateMixpanel];

    if ([(NSNumber *)[self.settings objectForKey:@"listen"] boolValue]) {
        SEGLog(@"Enabling Optimizely root.");
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(experimentDidGetViewed:)
                                                     name:OptimizelyExperimentVisitedNotification
                                                   object:nil];
    }

    [super start];
}

- (void)validate
{
    self.valid = YES;
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [self.optimizelyClass trackEvent:event];
    SEGLog(@"[Optimizely trackEvent:%@];", event);
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    [[self.optimizelyClass sharedInstance] setUserId:userId];
    SEGLog(@"[Optimizely sharedInstance].userId = %@;", userId);
}

#pragma mark - Private

+ (NSString *)identifier
{
    return @"Optimizely";
}

- (void)activateMixpanel
{
    if (NSClassFromString(SEGMixpanelClass) && self.needsToActivateMixpanel) {
        [self.optimizelyClass activateMixpanelIntegration];
        SEGLog(@"[Optimizely activateMixpanelIntegration];");
        self.needsToActivateMixpanel = NO;
    }
}

- (void)experimentDidGetViewed:(NSNotification *)notification
{
    NSString *experimentName = notification.name;
    for (OptimizelyExperimentData *data in [Optimizely sharedInstance].visitedExperiments) {
        if ([data.experimentName isEqualToString:experimentName]) {
            [[SEGAnalytics sharedAnalytics] track:@"Experiment Viewed"
                                       properties:@{
                                           @"experimentId" : data.experimentId,
                                           @"experimentName" : data.experimentName,
                                           @"variationId" : data.variationId,
                                           @"variationName" : data.variationName
                                       }];
            break;
        }
    }
}

- (void)integrationDidStart:(NSNotification *)notification
{
    SEGAnalyticsIntegration *integration = notification.object;

    if ([integration.name isEqualToString:@"Mixpanel"]) {
        self.needsToActivateMixpanel = YES;

        if (self.initialized) {
            [self activateMixpanel];
        }
    }
}

@end
