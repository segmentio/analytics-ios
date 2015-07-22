//
//  QuantcastProvider.m
//  Analytics
//
//  Created by Travis Jeffery on 4/26/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import "SEGQuantcastIntegration.h"
#import "SEGAnalytics.h"
#import "SEGAnalyticsUtils.h"


@implementation SEGQuantcastIntegration

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:[self name]];
}

- (id)init
{
    if (self = [super init]) {
        self.name = self.class.name;
        self.quantcast = [QuantcastMeasurement sharedInstance];
    }
    return self;
}

- (void)validate
{
    self.valid = self.settings[@"apiKey"] != nil;
}

- (void)start
{
    [self.quantcast setupMeasurementSessionWithAPIKey:self.settings[@"apiKey"] userIdentifier:self.settings[@"userIdentifier"] labels:self.settings[@"labels"]];
    [super start];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [self.quantcast logEvent:event withLabels:self.settings[@"labels"]];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [self.quantcast logEvent:SEGEventNameForScreenTitle(screenTitle) withLabels:self.settings[@"labels"]];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    [self.quantcast recordUserIdentifier:userId withLabels:self.settings[@"labels"]];
}

#pragma mark - Private

+ (NSString *)name
{
    return @"Quantcast";
}

@end
