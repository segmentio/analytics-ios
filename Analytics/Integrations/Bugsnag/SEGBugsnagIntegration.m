// BugsnagIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import "SEGBugsnagIntegration.h"
#import <Bugsnag/Bugsnag.h>
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"


@implementation SEGBugsnagIntegration

#pragma mark - Initialization

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:@"Bugsnag"];
}

- (id)init
{
    if (self = [super init]) {
        self.name = @"Bugsnag";
        self.valid = NO;
        self.initialized = NO;
        self.bugsnagClass = [Bugsnag class];
    }
    return self;
}

- (void)start
{
    NSString *apiKey = [self.settings objectForKey:@"apiKey"];
    [self.bugsnagClass startBugsnagWithApiKey:apiKey];
    SEGLog(@"BugsnagIntegration initialized with apiKey %@", apiKey);
    [super start];
    // TODO add support for non-SSL?
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasAPIKey = [self.settings objectForKey:@"apiKey"] != nil;
    self.valid = hasAPIKey;
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    // User ID
    [[self.bugsnagClass configuration] setUser:userId withName:[traits objectForKey:@"name"] andEmail:[traits objectForKey:@"email"]];

    // Other traits. Iterate over all the traits and set them.
    for (NSString *key in traits) {
        [self.bugsnagClass addAttribute:key withValue:[traits objectForKey:key] toTabWithName:@"user"];
    }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)optionsoptions
{
    [[self.bugsnagClass configuration] setContext:screenTitle];
}

@end
