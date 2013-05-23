// FlurryProvider.m
// Copyright 2013 Segment.io

#import "FlurryProvider.h"
#import "Flurry.h"


@implementation FlurryProvider {

}

#pragma mark - Initialization

+ (instancetype)withNothing
{
    return [[self alloc] initWithNothing];
}

- (id)initWithNothing
{
    if (self = [self init]) {
        self.name = @"Flurry";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    // Initialization
    NSString *apiKey = [self.settings objectForKey:@"apiKey"];
    [Flurry startSession:apiKey];
    NSLog(@"FlurryProvider initialized.");
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
    [Flurry setUserID:userId];

    // Gender
    NSString *gender = [traits objectForKey:@"gender"];
    if (gender) {
        [Flurry setGender:[gender substringToIndex:1]];
    }

    // Age
    NSString *age = [traits objectForKey:@"age"];
    if (age) {
        [Flurry setAge:[age integerValue]];
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    [Flurry logEvent:event withParameters:properties];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    // Flurry just counts the number of page views
    // http://stackoverflow.com/questions/5404513/tracking-page-views-with-the-help-of-flurry-sdk
    [Flurry logPageView];
}


@end
