// KahunaIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import "SEGKahunaDefines.h"
#import "SEGKahunaIntegration.h"
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"
#import <Kahuna/Kahuna.h>
#import <objc/runtime.h>

#define KAHUNA_NOT_STRING_NULL_EMPTY(obj) (obj != nil && [obj isKindOfClass:[NSString class]] && ![@"" isEqualToString:obj])

BOOL addedKAHMethodHandleActionWithIdentifierWithFetchCompletionHandler;

// Selectors that we are going to swizzle in this wrapper.
void (*selKAHOriginalApplicationDidFailToRegisterForRemoteNotificationsWithError)(id, SEL, id, id);
void (*selKAHOriginalApplicationDidReceiveRemoteNotification)(id, SEL, id, id);
void (*selKAHOriginalApplicationDidReceiveRemoteNotificationWithFetchCompletionHandler)(id, SEL, id, id, void (^)(UIBackgroundFetchResult result));
void (*selKAHOriginalApplicationHandleActionWithIdentifierWithFetchCompletionHandler)(id, SEL, id, id, id, void (^)());


@implementation SEGKahunaIntegration
@synthesize initialized, valid, name, settings;

#pragma mark - Initialization

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:@"Kahuna"];

    // When this class loads we will register for the 'UIApplicationDidFinishLaunchingNotification' notification.
    // To receive the notification we will use the SEGKahunaPushMonitor singleton instance.
    [[NSNotificationCenter defaultCenter] addObserver:[SEGKahunaPushMonitor sharedInstance]
                                             selector:@selector(didFinishLaunching:)
                                                 name:UIApplicationDidFinishLaunchingNotification
                                               object:nil];
}

- (id)init
{
    if (self = [super init]) {
        self.name = @"Kahuna";
        self.valid = NO;
        self.initialized = NO;
        self.kahunaClass = [Kahuna class];

        _kahunaCredentialsKeys = [NSSet setWithObjects:KAHUNA_CREDENTIAL_USERNAME,
                                                       KAHUNA_CREDENTIAL_EMAIL,
                                                       KAHUNA_CREDENTIAL_FACEBOOK,
                                                       KAHUNA_CREDENTIAL_TWITTER,
                                                       KAHUNA_CREDENTIAL_LINKEDIN,
                                                       KAHUNA_CREDENTIAL_USER_ID,
                                                       KAHUNA_CREDENTIAL_GOOGLE_PLUS,
                                                       KAHUNA_CREDENTIAL_INSTALL_TOKEN, nil];
    }
    return self;
}

- (void)start
{
    NSString *apiKey = [self.settings objectForKey:@"apiKey"];
    if (KAHUNA_NOT_STRING_NULL_EMPTY(apiKey)) {
        // We just need one call to launchWithKey and not multiple. The "start" method is called
        // everytime the app comes to foreground.
        if ([SEGKahunaPushMonitor sharedInstance].kahunaInitialized == NO) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wundeclared-selector"
            [self.kahunaClass performSelector:@selector(setSDKWrapper:withVersion:) withObject:SEGMENT withObject:[SEGAnalytics version]];
#pragma GCC diagnostic pop
            [self.kahunaClass launchWithKey:apiKey];

            // If we have a push token registration failure, then call the Kahuna handleNotificationRegistrationFailure method.
            if ([SEGKahunaPushMonitor sharedInstance].failedToRegisterError != nil) {
                [self.kahunaClass handleNotificationRegistrationFailure:[SEGKahunaPushMonitor sharedInstance].failedToRegisterError];
                [SEGKahunaPushMonitor sharedInstance].failedToRegisterError = nil;
            }

            // If we have recorded any push user info, then
            if ([SEGKahunaPushMonitor sharedInstance].pushInfo != nil) {
                [self.kahunaClass handleNotification:[SEGKahunaPushMonitor sharedInstance].pushInfo withApplicationState:[SEGKahunaPushMonitor sharedInstance].applicationState];
                [SEGKahunaPushMonitor sharedInstance].pushInfo = nil;
            }

            [SEGKahunaPushMonitor sharedInstance].kahunaInitialized = TRUE;
        }
    }

    [super start];
}

#pragma mark - Settings

- (void)validate
{
    self.valid = [self.settings objectForKey:@"apiKey"] != nil;
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    KahunaUserCredentials *credentials = [self.kahunaClass createUserCredentials];
    if (KAHUNA_NOT_STRING_NULL_EMPTY(userId)) {
        [credentials addCredential:KAHUNA_CREDENTIAL_USER_ID withValue:userId];
    }

    // We will go through each of the above keys, and try to see if the traits has that key. If it does, then we will add the key:value as a credential.
    // All other traits is being tracked as an attribute.
    for (NSString *eachKey in traits) {
        if (!KAHUNA_NOT_STRING_NULL_EMPTY(eachKey)) continue;

        NSString *eachValue = [traits objectForKey:eachKey];
        if (KAHUNA_NOT_STRING_NULL_EMPTY(eachValue)) {
            // Check if this is a Kahuna credential key.
            if ([_kahunaCredentialsKeys containsObject:eachKey]) {
                [credentials addCredential:eachKey withValue:eachValue];
            } else {
                [attributes setValue:eachValue forKey:eachKey];
            }
        } else if ([eachValue isKindOfClass:[NSNumber class]]) {
            // Check if this is a Kahuna credential key.
            if ([_kahunaCredentialsKeys containsObject:eachKey]) {
                [credentials addCredential:eachKey withValue:[NSString stringWithFormat:@"%@", eachValue]];
            } else {
                [attributes setValue:[NSString stringWithFormat:@"%@", eachValue] forKey:eachKey];
            }
        } else {
            @try {
                [attributes setValue:[eachValue description] forKey:eachKey];
            }
            @catch (NSException *exception) {
                // Do nothing.
            }
        }
    }

    NSError *error = nil;
    [self.kahunaClass loginWithCredentials:credentials error:&error];
    if (error) {
        NSLog(@"Kahuna-Segment Login Error : %@", error.description);
    }

    // Track the attributes if we have any items in it.
    if (attributes.count > 0) {
        [self.kahunaClass setUserAttributes:attributes];
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    NSNumber *revenue = [self.class extractRevenue:properties];
    NSNumber *quantity = nil;
    for (NSString *key in properties) {
        if (!KAHUNA_NOT_STRING_NULL_EMPTY(key)) continue;
        if ([key caseInsensitiveCompare:@"quantity"] == NSOrderedSame) {
            id value = properties[key];
            if ([value isKindOfClass:[NSString class]]) {
                quantity = [NSNumber numberWithLong:[value longLongValue]];
            } else if ([value isKindOfClass:[NSNumber class]]) {
                quantity = value;
            }

            break;
        }
    }

    // If we get revenue and quantity in the properties, then no matter what we will try to extract the numbers they hold and trackEvent with Count and Value.
    if (revenue && quantity) {
        // Get the count and value from quantity and revenue.
        long value = (long)([revenue doubleValue] * 100);
        long count = [quantity longValue];

        [self.kahunaClass trackEvent:event withCount:count andValue:value];
    } else {
        [self.kahunaClass trackEvent:event];
    }

    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *lowerCaseKeyProperties = [[NSMutableDictionary alloc] init];

    // Lower case all the keys and copy over the properties into a new dictionary.
    for (NSString *eachKey in properties) {
        if (!KAHUNA_NOT_STRING_NULL_EMPTY(eachKey)) continue;
        [lowerCaseKeyProperties setValue:properties[eachKey] forKey:[eachKey lowercaseString]];
    }

    if ([event caseInsensitiveCompare:KAHUNA_VIEWED_PRODUCT_CATEGORY] == NSOrderedSame) {
        [self addViewedProductCategoryElements:&attributes fromProperties:lowerCaseKeyProperties];
    } else if ([event caseInsensitiveCompare:KAHUNA_VIEWED_PRODUCT] == NSOrderedSame) {
        [self addViewedProductElements:&attributes fromProperties:lowerCaseKeyProperties];
    } else if ([event caseInsensitiveCompare:KAHUNA_ADDED_PRODUCT] == NSOrderedSame) {
        [self addAddedProductElements:&attributes fromProperties:lowerCaseKeyProperties];
    } else if ([event caseInsensitiveCompare:KAHUNA_COMPLETED_ORDER] == NSOrderedSame) {
        [self addCompletedOrderElements:&attributes fromProperties:lowerCaseKeyProperties];
    }

    // If we have collected any attributes, then we will call the setUserAttributes API
    if (attributes.count > 0) {
        [self.kahunaClass setUserAttributes:attributes];
    }
}

- (void)addViewedProductCategoryElements:(NSMutableDictionary *__autoreleasing *)attributes fromProperties:(NSDictionary *)properties
{
    id value = properties[KAHUNA_CATEGORY];
    if (value && ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]])) {
        [(*attributes)setValue:value forKey:KAHUNA_LAST_VIEWED_CATEGORY];
        NSDictionary *existingAttributes = [self.kahunaClass getUserAttributes];
        id categoriesViewed = [existingAttributes valueForKey:KAHUNA_CATEGORIES_VIEWED];
        if (categoriesViewed && [categoriesViewed isKindOfClass:[NSString class]]) {
            NSMutableArray *aryOfCategoriesViewed = [[categoriesViewed componentsSeparatedByString:@","] mutableCopy];
            if (![aryOfCategoriesViewed containsObject:value]) {
                if (aryOfCategoriesViewed.count > 50) {
                    [aryOfCategoriesViewed removeObjectAtIndex:0]; // Remove the first object.
                }

                [aryOfCategoriesViewed addObject:value];
                [(*attributes)setValue:[aryOfCategoriesViewed componentsJoinedByString:@","] forKey:KAHUNA_CATEGORIES_VIEWED];
            }
        } else {
            [(*attributes)setValue:value forKey:KAHUNA_CATEGORIES_VIEWED];
        }
    } else {
        // Since we do not have a category, we will store "none" for last view category and categories viewed list.
        [(*attributes)setValue:KAHUNA_NONE forKey:KAHUNA_LAST_VIEWED_CATEGORY];
        [(*attributes)setValue:KAHUNA_NONE forKey:KAHUNA_CATEGORIES_VIEWED];
    }
}

- (void)addViewedProductElements:(NSMutableDictionary *__autoreleasing *)attributes fromProperties:(NSDictionary *)properties
{
    id kname = properties[KAHUNA_NAME];
    if (KAHUNA_NOT_STRING_NULL_EMPTY(kname)) {
        [(*attributes)setValue:kname forKey:KAHUNA_LAST_PRODUCT_VIEWED_NAME];
    }

    [self addViewedProductCategoryElements:attributes fromProperties:properties];
}

- (void)addAddedProductElements:(NSMutableDictionary *__autoreleasing *)attributes fromProperties:(NSDictionary *)properties
{
    id kname = properties[KAHUNA_NAME];
    if (KAHUNA_NOT_STRING_NULL_EMPTY(kname)) {
        [(*attributes)setValue:kname forKey:KAHUNA_LAST_PRODUCT_ADDED_TO_CART_NAME];
    }

    id category = properties[KAHUNA_CATEGORY];
    if (!KAHUNA_NOT_STRING_NULL_EMPTY(category)) {
        category = KAHUNA_NONE;
    }

    [(*attributes)setValue:category forKey:KAHUNA_LAST_PRODUCT_ADDED_TO_CART_CATEGORY];
}

- (void)addCompletedOrderElements:(NSMutableDictionary *__autoreleasing *)attributes fromProperties:(NSDictionary *)properties
{
    id discount = properties[KAHUNA_DISCOUNT];
    if ([discount isKindOfClass:[NSString class]] || [discount isKindOfClass:[NSNumber class]]) {
        [(*attributes)setValue:discount forKey:KAHUNA_LAST_PURCHASE_DISCOUNT];
    } else {
        [(*attributes)setValue:@0 forKey:KAHUNA_LAST_PURCHASE_DISCOUNT];
    }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    BOOL trackAllPages = [(NSNumber *)[self.settings objectForKey:@"trackAllPages"] boolValue];
    if (trackAllPages && KAHUNA_NOT_STRING_NULL_EMPTY(screenTitle)) {
        // Track the screen view as an event.
        [self track:SEGEventNameForScreenTitle(screenTitle) properties:properties options:options];
    }
}

- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken options:(NSDictionary *)options
{
    [self.kahunaClass setDeviceToken:deviceToken];
}

- (void)reset
{
    [self.kahunaClass logout];
}

@end

// This class is responsible for getting the 'UIApplicationDidFinishLaunchingNotification' notification. It is received by the
// method didFinishLaunching and it calls [self.kahunaClass handleNotification API.
@implementation SEGKahunaPushMonitor

+ (instancetype)sharedInstance
{
    static SEGKahunaPushMonitor *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      instance = [[SEGKahunaPushMonitor alloc] init];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.kahunaClass = [Kahuna class];
        return self;
    }

    return nil;
}

- (void)didFinishLaunching:(NSNotification *)notificationPayload
{
    NSDictionary *userInfo = notificationPayload.userInfo;
    if ([userInfo valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
        NSDictionary *remoteNotification = [userInfo valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        [SEGKahunaPushMonitor sharedInstance].pushInfo = remoteNotification;
        [SEGKahunaPushMonitor sharedInstance].applicationState = UIApplicationStateInactive;
    }

    // We will also swizzle the app delegate methods now. We need this so that we can intercept the registration for device token
    // and a push being received when the app is in foreground or background.
    [self swizzleAppDelegateMethods];
}

// App Delegate methods that deal with push notifications need to be swizzled here. That way this class will receive the delegate callbacks
// and access the necesary details from each callback.
- (void)swizzleAppDelegateMethods
{
    @try {
        // ####### didFailToRegisterForRemoteNotificationsWithError  #######
        SEL selector = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
        if ([[UIApplication sharedApplication].delegate respondsToSelector:selector]) {
            selKAHOriginalApplicationDidFailToRegisterForRemoteNotificationsWithError = (void (*)(id, SEL, id, id))[[[UIApplication sharedApplication].delegate class] instanceMethodForSelector:selector];
        } else {
            Method methodSegmentWrapper = class_getInstanceMethod([self class], selector);
            const char *methodTypeEncoding = method_getTypeEncoding(methodSegmentWrapper);

            IMP implementationSegmentWrapper = class_getMethodImplementation([self class], selector);
            class_addMethod([[UIApplication sharedApplication].delegate class], selector, implementationSegmentWrapper, methodTypeEncoding);
        }

        // ####### didReceiveRemoteNotification  #######
        selector = @selector(application:didReceiveRemoteNotification:);
        if ([[UIApplication sharedApplication].delegate respondsToSelector:selector]) {
            selKAHOriginalApplicationDidReceiveRemoteNotification = (void (*)(id, SEL, id, id))[[[UIApplication sharedApplication].delegate class] instanceMethodForSelector:selector];
        } else {
            Method methodSegmentWrapper = class_getInstanceMethod([self class], selector);
            const char *methodTypeEncoding = method_getTypeEncoding(methodSegmentWrapper);

            IMP implementationSegmentWrapper = class_getMethodImplementation([self class], selector);
            class_addMethod([[UIApplication sharedApplication].delegate class], selector, implementationSegmentWrapper, methodTypeEncoding);
        }

        // ####### didReceiveRemoteNotification:fetchCompletionHandler  #######
        selector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
        if ([[UIApplication sharedApplication].delegate respondsToSelector:selector]) {
            selKAHOriginalApplicationDidReceiveRemoteNotificationWithFetchCompletionHandler = (void (*)(id, SEL, id, id, void (^)(UIBackgroundFetchResult result)))[[[UIApplication sharedApplication].delegate class] instanceMethodForSelector:selector];
        }

        // ####### handleActionWithIdentifier:forRemoteNotification:completionHandler  #######
        selector = @selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:);
        if ([[UIApplication sharedApplication].delegate respondsToSelector:selector]) {
            selKAHOriginalApplicationHandleActionWithIdentifierWithFetchCompletionHandler = (void (*)(id, SEL, id, id, id, void (^)()))[[[UIApplication sharedApplication].delegate class] instanceMethodForSelector:selector];
        } else {
            Method methodSegmentWrapper = class_getInstanceMethod([self class], selector);
            const char *methodTypeEncoding = method_getTypeEncoding(methodSegmentWrapper);

            IMP implementationSegmentWrapper = class_getMethodImplementation([self class], selector);
            addedKAHMethodHandleActionWithIdentifierWithFetchCompletionHandler = class_addMethod([[UIApplication sharedApplication].delegate class], selector, implementationSegmentWrapper, methodTypeEncoding);
        }

        // Swizzle the methods only if we got the original Application selector. Otherwise no point doing the swizzling.
        Method methodSegmentWrapper = nil;
        Method methodHostApp = nil;

        // Swizzling didFailToRegisterForRemoteNotificationsWithError
        if (selKAHOriginalApplicationDidFailToRegisterForRemoteNotificationsWithError) {
            methodSegmentWrapper = class_getInstanceMethod([self class], @selector(application:didFailToRegisterForRemoteNotificationsWithError:));
            methodHostApp = class_getInstanceMethod([[UIApplication sharedApplication].delegate class], @selector(application:didFailToRegisterForRemoteNotificationsWithError:));
            method_exchangeImplementations(methodSegmentWrapper, methodHostApp);
        }

        // Swizzling didReceiveRemoteNotification
        if (selKAHOriginalApplicationDidReceiveRemoteNotification) {
            methodSegmentWrapper = class_getInstanceMethod([self class], @selector(application:didReceiveRemoteNotification:));
            methodHostApp = class_getInstanceMethod([[UIApplication sharedApplication].delegate class], @selector(application:didReceiveRemoteNotification:));
            method_exchangeImplementations(methodSegmentWrapper, methodHostApp);
        }

        if (selKAHOriginalApplicationDidReceiveRemoteNotificationWithFetchCompletionHandler) {
            methodSegmentWrapper = class_getInstanceMethod([self class], @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:));
            methodHostApp = class_getInstanceMethod([[UIApplication sharedApplication].delegate class], @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:));
            method_exchangeImplementations(methodSegmentWrapper, methodHostApp);
        }

        selector = @selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:);
        if (selKAHOriginalApplicationHandleActionWithIdentifierWithFetchCompletionHandler) {
            methodSegmentWrapper = class_getInstanceMethod([self class], selector);
            methodHostApp = class_getInstanceMethod([[UIApplication sharedApplication].delegate class], selector);
            method_exchangeImplementations(methodSegmentWrapper, methodHostApp);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Kahuna-Segment Exception : %@", exception.description);
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    @try {
        [[SEGKahunaPushMonitor sharedInstance] failedToRegisterPush:error];

        if (selKAHOriginalApplicationDidFailToRegisterForRemoteNotificationsWithError) {
            selKAHOriginalApplicationDidFailToRegisterForRemoteNotificationsWithError([UIApplication sharedApplication].delegate,
                                                                                      @selector(application:didFailToRegisterForRemoteNotificationsWithError:),
                                                                                      application,
                                                                                      error);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Kahuna-Segment Exception : %@", exception.description);
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    @try {
        [[SEGKahunaPushMonitor sharedInstance] pushReceived:userInfo];
        if (selKAHOriginalApplicationDidReceiveRemoteNotification) {
            selKAHOriginalApplicationDidReceiveRemoteNotification([UIApplication sharedApplication].delegate,
                                                                  @selector(application:didReceiveRemoteNotification:),
                                                                  application,
                                                                  userInfo);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Kahuna-Segment Exception : %@", exception.description);
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    @try {
        [[SEGKahunaPushMonitor sharedInstance] pushReceived:userInfo];
        if (selKAHOriginalApplicationDidReceiveRemoteNotificationWithFetchCompletionHandler) {
            selKAHOriginalApplicationDidReceiveRemoteNotificationWithFetchCompletionHandler([UIApplication sharedApplication].delegate,
                                                                                            @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:),
                                                                                            application,
                                                                                            userInfo,
                                                                                            completionHandler);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Kahuna-Segment Exception : %@", exception.description);
    }
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler
{
    @try {
        [[SEGKahunaPushMonitor sharedInstance] pushReceived:userInfo];
        if (selKAHOriginalApplicationHandleActionWithIdentifierWithFetchCompletionHandler) {
            selKAHOriginalApplicationHandleActionWithIdentifierWithFetchCompletionHandler([UIApplication sharedApplication].delegate,
                                                                                          @selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:),
                                                                                          application,
                                                                                          identifier,
                                                                                          userInfo,
                                                                                          completionHandler);
        } else {
            if (addedKAHMethodHandleActionWithIdentifierWithFetchCompletionHandler) {
                completionHandler();
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Kahuna-Segment Exception : %@", exception.description);
    }
}

- (void)pushReceived:(NSDictionary *)userInfo
{
    // When we get this notification, check if kahuna is initialized. If not store it for future use.
    if ([SEGKahunaPushMonitor sharedInstance].kahunaInitialized) {
        [self.kahunaClass handleNotification:userInfo withApplicationState:[UIApplication sharedApplication].applicationState];
    } else {
        [SEGKahunaPushMonitor sharedInstance].pushInfo = userInfo;
        [SEGKahunaPushMonitor sharedInstance].applicationState = [UIApplication sharedApplication].applicationState;
    }
}

- (void)failedToRegisterPush:(NSError *)error
{
    // When we get this failure, check if kahuna is initialized. If not store it for future use.
    if ([SEGKahunaPushMonitor sharedInstance].kahunaInitialized) {
        [self.kahunaClass handleNotificationRegistrationFailure:error];
    } else {
        [SEGKahunaPushMonitor sharedInstance].failedToRegisterError = error;
    }
}

@end
