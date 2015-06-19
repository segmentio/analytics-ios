#import "SEGFlurryIntegration.h"
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"
#import <Flurry.h>
#import <objc/message.h>


@implementation SEGFlurryIntegration

#pragma mark - Initialization

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:@"Flurry"];
}

- (id)init
{
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
    NSNumber *sessionContinueSeconds = self.settings[@"sessionContinueSeconds"];
    if (sessionContinueSeconds) {
        [Flurry setSessionContinueSeconds:[sessionContinueSeconds intValue]];
    }

    // Start the session
    NSString *apiKey = self.settings[@"apiKey"];
    [Flurry startSession:apiKey];
    SEGLog(@"FlurryIntegration initialized.");
    [super start];
}

#pragma mark - Settings

- (void)validate
{
    BOOL hasAPIKey = self.settings[@"apiKey"] != nil;
    self.valid = hasAPIKey;
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    [Flurry setUserID:userId];

    NSString *gender = traits[@"gender"];
    if (gender) {
        [Flurry setGender:[gender substringToIndex:1]];
    }

    NSString *age = traits[@"age"];
    if (age) {
        [Flurry setAge:[age intValue]];
    }

    NSDictionary *location = traits[@"location"];
    if (location) {
        float latitude = [location[@"latitude"] floatValue];
        float longitude = [location[@"longitude"] floatValue];
        float horizontalAccuracy = [location[@"horizontalAccuracy"] floatValue];
        float verticalAccuracy = [location[@"verticalAccuracy"] floatValue];
        [Flurry setLatitude:latitude longitude:longitude horizontalAccuracy:horizontalAccuracy verticalAccuracy:verticalAccuracy];
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [Flurry logEvent:event withParameters:properties];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    if (self.settings[@"screenTracksEvents"]) {
        [self track:SEGEventNameForScreenTitle(screenTitle) properties:properties options:options];
    }

    // Flurry just counts the number of page views
    // http://stackoverflow.com/questions/5404513/tracking-page-views-with-the-help-of-flurry-sdk

    [Flurry logPageView];
}

- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken options:(NSDictionary *)options
{
    // Why oh why does Flurry require an NSString?! NSData was good enough for everyone else lol
    // http://stackoverflow.com/a/9372848/1426850
    const unsigned *tokenBytes = [deviceToken bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                                                    ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                                                    ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                                                    ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    // cocoapods validation cant find +[Flurry setPushToken:]
    ((void (*)(Class, SEL, NSString *))objc_msgSend)(Flurry.class, NSSelectorFromString(@"setPushToken:"), hexToken);
}

@end
