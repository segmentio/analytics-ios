// BugsnagProvider.m
// Copyright 2013 Segment.io

#import "BugsnagProvider.h"
#import "Bugsnag.h"
#import "AnalyticsLogger.h"


@implementation BugsnagProvider {

}

#pragma mark - Initialization

+ (instancetype)withNothing
{
    return [[self alloc] initWithNothing];
}

- (id)initWithNothing
{
    if (self = [self init]) {
        self.name = @"Bugsnag";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    // Initialization
    NSString *apiKey = [self.settings objectForKey:@"apiKey"];
    [Bugsnag startBugsnagWithApiKey:apiKey];
    [AnalyticsLogger log:@"BugsnagProvider initialized."];

    // TODO add support for non-SSL?
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasAPIKey = [self.settings objectForKey:@"apiKey"] != nil;
    self.valid = hasAPIKey;
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context
{
    // User ID
    [Bugsnag instance].userId = userId;

    // Other traits. Iterate over all the traits and set them.
    for (NSString *key in traits) {
        [Bugsnag addAttribute:key withValue:[traits objectForKey:key] toTabWithName:@"user"];
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    // There's no event tracking with Bugsnag.
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    [Bugsnag instance].context = screenTitle;
}


@end
