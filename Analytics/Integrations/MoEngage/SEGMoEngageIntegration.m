//
//  SEGMoEngageIntegration.m
//  Analytics
//
//  Created by Gautam on 28/05/15.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import "SEGMoEngageIntegration.h"
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"
#import <MoEngage-iOS-SDK/MoEngage.h>
#import <MoEngage-iOS-SDK/MOEHelperConstants.h>
#import <objc/runtime.h>

// Selectors that we are going to swizzle in this wrapper.
void (*selOriginalApplicationDidFailToRegisterForRemoteNotificationsWithError)(id, SEL, id, id);
void (*selOriginalApplicationDidReceiveRemoteNotification)(id, SEL, id, id);


@implementation SEGMoEngageIntegration
@synthesize name, valid, initialized, settings;

- (instancetype)init
{
    if (self = [super init]) {
        self.name = @"MoEngage";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:@"MoEngage"];
}

- (void)start
{
    NSString *apiKey = [self.settings objectForKey:@"apiKey"];
    if (!apiKey.length) {
        SEGLog(@"MoEngage-Segment - api key not present");
        return;
    }

    // We just need one call to initialize. The "start" method is called
    // everytime the app comes to foreground.
    if ([SEGMoEngagePushManager sharedInstance].moengageInitialized == NO) {
        [[MoEngage sharedInstance] initializeWithApiKey:apiKey inApplication:[UIApplication sharedApplication] withLaunchOptions:[SEGMoEngagePushManager sharedInstance].pushInfoDict];

        // If we have recorded any push user info, then
        if ([SEGMoEngagePushManager sharedInstance].pushInfoDict != nil) {
            [[MoEngage sharedInstance] didReceieveNotificationinApplication:[UIApplication sharedApplication] withInfo:[SEGMoEngagePushManager sharedInstance].pushInfoDict];
            [SEGMoEngagePushManager sharedInstance].pushInfoDict = nil;
        }

        [SEGMoEngagePushManager sharedInstance].moengageInitialized = TRUE;
        SEGLog(@"MoEngage-Segment - initialized.");
    }

    // When this class loads we will register for the 'UIApplicationDidFinishLaunchingNotification' notification.
    // To receive the notification we will use the SEGMoEngagePushManager singleton instance.
    [[NSNotificationCenter defaultCenter] addObserver:[SEGMoEngagePushManager sharedInstance]
                                             selector:@selector(didFinishLaunching:)
                                                 name:UIApplicationDidFinishLaunchingNotification
                                               object:nil];
    [super start];
}

- (void)validate
{
    self.valid = [self.settings objectForKey:@"apiKey"] != nil;
}

- (void)flush
{
    [[MoEngage sharedInstance] syncNow];
}

- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken options:(NSDictionary *)options
{
    [[MoEngage sharedInstance] registerForPush:deviceToken];
}

- (void)reset
{
    [[MoEngage sharedInstance] resetUser];
}

#pragma mark - Event and user tracking

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [[MoEngage sharedInstance] trackEvent:event andPayload:[NSMutableDictionary dictionaryWithDictionary:properties]];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    if (!userId) {
        NSLog(@"MoEngage-Segment - calling identify without any userId");
    }
    [self setAttributes:traits];
}

- (void)setAttributes:(NSDictionary *)traits
{
    if ([traits objectForKey:@"id"]) {
        [[MoEngage sharedInstance] setUserAttribute:[traits objectForKey:@"id"] forKey:USER_ATTRIBUTE_UNIQUE_ID];
    }

    if ([traits objectForKey:@"email"]) {
        [[MoEngage sharedInstance] setUserAttribute:[traits objectForKey:@"email"] forKey:USER_ATTRIBUTE_USER_EMAIL];
    }

    if ([traits objectForKey:@"name"]) {
        [[MoEngage sharedInstance] setUserAttribute:[traits objectForKey:@"username"] forKey:USER_ATTRIBUTE_USER_NAME];
    }

    if ([traits objectForKey:@"phone"]) {
        [[MoEngage sharedInstance] setUserAttribute:[traits objectForKey:@"phone"] forKey:USER_ATTRIBUTE_USER_MOBILE];
    }

    if ([traits objectForKey:@"firstName"]) {
        [[MoEngage sharedInstance] setUserAttribute:[traits objectForKey:@"firstName"] forKey:USER_ATTRIBUTE_USER_FIRST_NAME];
    }

    if ([traits objectForKey:@"lastName"]) {
        [[MoEngage sharedInstance] setUserAttribute:[traits objectForKey:@"lastName"] forKey:USER_ATTRIBUTE_USER_LAST_NAME];
    }

    if ([traits objectForKey:@"gender"]) {
        [[MoEngage sharedInstance] setUserAttribute:[traits objectForKey:@"gender"] forKey:USER_ATTRIBUTE_USER_GENDER];
    }

    if ([traits objectForKey:@"birthday"]) {
        [[MoEngage sharedInstance] setUserAttribute:[traits objectForKey:@"birthday"] forKey:USER_ATTRIBUTE_USER_BDAY];
    }

    if ([traits objectForKey:@"address"]) {
        [[MoEngage sharedInstance] setUserAttribute:[traits objectForKey:@"address"] forKey:@"address"];
    }

    if ([traits objectForKey:@"age"]) {
        [[MoEngage sharedInstance] setUserAttribute:[traits objectForKey:@"age"] forKey:@"age"];
    }
}

#pragma mark - App state changes

- (void)applicationDidBecomeActive
{
    [[MoEngage sharedInstance] applicationBecameActiveinApplication:[UIApplication sharedApplication]];
}

- (void)applicationDidEnterBackground
{
    [[MoEngage sharedInstance] stop:[UIApplication sharedApplication]];
}

- (void)applicationWillTerminate
{
    [[MoEngage sharedInstance] applicationTerminated:[UIApplication sharedApplication]];
}

@end

#pragma mark - Push Manager


@implementation SEGMoEngagePushManager

+ (instancetype)sharedInstance
{
    static SEGMoEngagePushManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      instance = [[SEGMoEngagePushManager alloc] init];
    });
    return instance;
}

- (void)didFinishLaunching:(NSNotification *)notificationPayload
{
    NSDictionary *userInfo = notificationPayload.userInfo;
    if ([userInfo valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
        NSDictionary *remoteNotification = [userInfo valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        [SEGMoEngagePushManager sharedInstance].pushInfoDict = remoteNotification;
    }

    // We will also swizzle the app delegate methods now. We need this so that we can intercept the registration for device token
    // and a push being received when the app is in foreground or background.
    [self swizzleAppDelegateMethods];
}

#pragma mark - App Delegate Methods Swizzling
// App Delegate methods that deal with push notifications need to be swizzled here. That way this class will receive the delegate callbacks
// and access the necesary details from each callback.
- (void)swizzleAppDelegateMethods
{
    @try {
        SEL selector = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
        if ([[UIApplication sharedApplication].delegate respondsToSelector:selector]) {
            selOriginalApplicationDidFailToRegisterForRemoteNotificationsWithError = (void (*)(id, SEL, id, id))[[[UIApplication sharedApplication].delegate class] instanceMethodForSelector:selector];
        } else {
            Method methodSegmentWrapper = class_getInstanceMethod([self class], selector);
            const char *methodTypeEncoding = method_getTypeEncoding(methodSegmentWrapper);

            IMP implementationSegmentWrapper = class_getMethodImplementation([self class], selector);
            class_addMethod([[UIApplication sharedApplication].delegate class], selector, implementationSegmentWrapper, methodTypeEncoding);
        }

        selector = @selector(application:didReceiveRemoteNotification:);
        if ([[UIApplication sharedApplication].delegate respondsToSelector:selector]) {
            selOriginalApplicationDidReceiveRemoteNotification = (void (*)(id, SEL, id, id))[[[UIApplication sharedApplication].delegate class] instanceMethodForSelector:selector];
        } else {
            Method methodSegmentWrapper = class_getInstanceMethod([self class], selector);
            const char *methodTypeEncoding = method_getTypeEncoding(methodSegmentWrapper);

            IMP implementationSegmentWrapper = class_getMethodImplementation([self class], selector);
            class_addMethod([[UIApplication sharedApplication].delegate class], selector, implementationSegmentWrapper, methodTypeEncoding);
        }

        // Swizzle the methods only if we got the original Application selector. Otherwise no point doing the swizzling.
        Method newMethod = nil;
        Method originalMethod = nil;

        // Swizzling didFailToRegisterForRemoteNotificationsWithError
        if (selOriginalApplicationDidFailToRegisterForRemoteNotificationsWithError) {
            newMethod = class_getInstanceMethod([self class], @selector(application:didFailToRegisterForRemoteNotificationsWithError:));
            originalMethod = class_getInstanceMethod([[UIApplication sharedApplication].delegate class], @selector(application:didFailToRegisterForRemoteNotificationsWithError:));
            method_exchangeImplementations(newMethod, originalMethod);
        }

        // Swizzling didReceiveRemoteNotification
        if (selOriginalApplicationDidReceiveRemoteNotification) {
            newMethod = class_getInstanceMethod([self class], @selector(application:didReceiveRemoteNotification:));
            originalMethod = class_getInstanceMethod([[UIApplication sharedApplication].delegate class], @selector(application:didReceiveRemoteNotification:));
            method_exchangeImplementations(newMethod, originalMethod);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"MoEngage-Segment Exception : %@", exception.description);
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    @try {
        if ([SEGMoEngagePushManager sharedInstance].moengageInitialized) {
            [[MoEngage sharedInstance] didFailToRegisterForPush];
        }

        if (selOriginalApplicationDidFailToRegisterForRemoteNotificationsWithError) {
            selOriginalApplicationDidFailToRegisterForRemoteNotificationsWithError([UIApplication sharedApplication].delegate,
                                                                                   @selector(application:didFailToRegisterForRemoteNotificationsWithError:),
                                                                                   application,
                                                                                   error);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"MoEngage-Segment Exception : %@", exception.description);
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    @try {
        [self pushReceived:userInfo];
        if (selOriginalApplicationDidReceiveRemoteNotification) {
            selOriginalApplicationDidReceiveRemoteNotification([UIApplication sharedApplication].delegate,
                                                               @selector(application:didReceiveRemoteNotification:),
                                                               application,
                                                               userInfo);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"MoEngage-Segment Exception : %@", exception.description);
    }
}

- (void)pushReceived:(NSDictionary *)userInfo
{
    // When we get this notification, check if MoEngage is initialized. If not store it for future use.
    if ([SEGMoEngagePushManager sharedInstance].moengageInitialized) {
        [[MoEngage sharedInstance] didReceieveNotificationinApplication:[UIApplication sharedApplication] withInfo:userInfo];
    } else {
        [SEGMoEngagePushManager sharedInstance].pushInfoDict = userInfo;
    }
}

@end
