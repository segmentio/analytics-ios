// FlurryProvider.m
// Copyright 2013 Segment.io

#import "FlurryProvider.h"
#import "Flurry.h"
#import "AnalyticsUtils.h"
#import "Analytics.h"

@implementation FlurryProvider

#pragma mark - Initialization

+ (void)load {
    [Analytics registerProvider:self withIdentifier:@"Flurry"];
}

- (id)init {
    if (self = [super init]) {
        self.name = @"Flurry";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    // Session settings
    NSNumber *sessionContinueSeconds = [self.settings objectForKey:@"sessionContinueSeconds"];
    if (sessionContinueSeconds) {
        [Flurry setSessionContinueSeconds:[sessionContinueSeconds intValue]];
    }
    
    // Start the session
    NSString *apiKey = [self.settings objectForKey:@"apiKey"];
    [Flurry startSession:apiKey];
    SOLog(@"FlurryProvider initialized.");
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
    [Flurry setUserID:userId];

    // Gender
    NSString *gender = [traits objectForKey:@"gender"];
    if (gender) {
        [Flurry setGender:[gender substringToIndex:1]];
    }

    // Age
    NSString *age = [traits objectForKey:@"age"];
    if (age) {
        [Flurry setAge:[age intValue]];
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [Flurry logEvent:event withParameters:properties];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    // Flurry just counts the number of page views
    // http://stackoverflow.com/questions/5404513/tracking-page-views-with-the-help-of-flurry-sdk
    [Flurry logPageView];
}

- (void)registerPushDeviceToken:(NSData *)deviceToken {
    // Why oh why does Flurry require an NSString?! NSData was good enough for everyone else lol
    // http://stackoverflow.com/a/9372848/1426850
    const unsigned *tokenBytes = [deviceToken bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    [Flurry setPushToken:hexToken];
}



@end
