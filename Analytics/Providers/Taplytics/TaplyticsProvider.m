// TaplyticsProvider.m
// Copyright 2013 Segment.io

#import "TaplyticsProvider.h"
#import "Taplytics.h"
#import "AnalyticsUtils.h"
#import "Analytics.h"

@implementation TaplyticsProvider

#pragma mark - Initialization

+ (void)load {
    [Analytics registerProvider:self withIdentifier:@"Taplytics"];
}

- (id)init {
    if (self = [super init]) {
        self.name = @"Taplytics";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    NSString *apiKey = [self.settings objectForKey:@"apiKey"];
    [Taplytics startTaplyticsAPIKey:apiKey];
    SOLog(@"TaplyticsProvider initialized.");
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasApiKey = [self.settings objectForKey:@"apiKey"] != nil;
    self.valid = hasApiKey;
}

@end
