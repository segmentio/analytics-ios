// KahunaIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import "SEGKahunaIntegration.h"
#import "KahunaAnalytics.h"
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"
#import <objc/runtime.h>

#define KAHUNA_NOT_STRING_NULL_EMPTY(obj) (obj != nil \
&& [obj isKindOfClass:[NSString class]] \
&& ![@"" isEqualToString:obj])

BOOL addedMethodHandleActionWithIdentifierWithFetchCompletionHandler;

// Selectors that we are going to swizzle in this wrapper.
void (*selOriginalApplicationDidFailToRegisterForRemoteNotificationsWithError)(id, SEL, id, id);
void (*selOriginalApplicationDidReceiveRemoteNotification)(id, SEL, id, id);
void (*selOriginalApplicationDidReceiveRemoteNotificationWithFetchCompletionHandler)(id, SEL, id, id, void (^)(UIBackgroundFetchResult result));
void (*selOriginalApplicationHandleActionWithIdentifierWithFetchCompletionHandler)(id, SEL, id, id, id, void (^)());

static NSString* const KAHUNA_VIEWED_PRODUCT_CATEGORY = @"Viewed Product Category";
static NSString* const KAHUNA_VIEWED_PRODUCT = @"Viewed Product";
static NSString* const KAHUNA_ADDED_PRODUCT = @"Added Product";
static NSString* const KAHUNA_COMPLETED_ORDER = @"Completed Order";

static NSString* const KAHUNA_LAST_VIEWED_CATEGORY = @"Last Viewed Category";
static NSString* const KAHUNA_CATEGORIES_VIEWED = @"Categories Viewed";
static NSString* const KAHUNA_LAST_PRODUCT_VIEWED_NAME = @"Last Product Viewed Name";
static NSString* const KAHUNA_LAST_PRODUCT_VIEWED_ID = @"Last Produced Viewed Id";
static NSString* const KAHUNA_LAST_PRODUCT_ADDED_TO_CART_NAME = @"Last Product Added To Cart Name";
static NSString* const KAHUNA_LAST_PRODUCT_ADDED_TO_CART_CATEGORY = @"Last Product Added To Cart Category";
static NSString* const KAHUNA_LAST_PURCHASE_DISCOUNT = @"Last Purchase Discount";

static NSString* const KAHUNA_CATEGORY = @"category";
static NSString* const KAHUNA_NAME = @"name";
static NSString* const KAHUNA_ID = @"id";
static NSString* const KAHUNA_DISCOUNT = @"discount";
static NSString* const KAHUNA_NONE = @"None";

@implementation SEGKahunaIntegration
@synthesize initialized, valid, name, settings;

#pragma mark - Initialization

+ (void)load {
  [SEGAnalytics registerIntegration:self withIdentifier:@"Kahuna"];
  
  // When this class loads we will register for the 'UIApplicationDidFinishLaunchingNotification' notification.
  // To receive the notification we will use the KahunaPushMonitor singleton instance.
  [[NSNotificationCenter defaultCenter] addObserver:[KahunaPushMonitor sharedInstance]
                                           selector:@selector(didFinishLaunching:)
                                               name:UIApplicationDidFinishLaunchingNotification
                                             object:nil];

}

- (id)init {
  if (self = [super init]) {
    self.name = @"Kahuna";
    self.valid = NO;
    self.initialized = NO;
    
    _kahunaCredentialsKeys = [NSSet setWithObjects:       KAHUNA_CREDENTIAL_USERNAME,
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

- (void)start {
  @try {
    // We just need one call to launchWithKey and not multiple.
    if ([KahunaPushMonitor sharedInstance].kahunaInitialized == NO) {
      [KahunaAnalytics launchWithKey:[self.settings objectForKey:@"apiKey"]];
      // If we have recorded any push user info, then
      if ([KahunaPushMonitor sharedInstance].pushInfo != nil) {
        [KahunaAnalytics handleNotification:[KahunaPushMonitor sharedInstance].pushInfo withApplicationState:[KahunaPushMonitor sharedInstance].applicationState];
        [KahunaPushMonitor sharedInstance].pushInfo = nil;
      }
      
      [KahunaPushMonitor sharedInstance].kahunaInitialized = TRUE;
    }
    
    [super start];
  }
  @catch (NSException *exception) {
    NSLog (@"Kahuna-Segment Exception : %@", exception.description);
  }
}

#pragma mark - Settings

- (void)validate {
  self.valid = [self.settings objectForKey:@"apiKey"] != nil;
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {
  @try {
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    if (KAHUNA_NOT_STRING_NULL_EMPTY (userId)) {
      [KahunaAnalytics setUserCredentialsWithKey:KAHUNA_CREDENTIAL_USER_ID andValue:userId];
    }
    
    // We will go through each of the above keys, and try to see if the traits has that key. If it does, then we will add the key:value as a credential.
    // All other traits is being tracked as an attribute.
    for (NSString *eachKey in traits) {
      if (!KAHUNA_NOT_STRING_NULL_EMPTY (eachKey)) continue;
      
      NSString *eachValue = [traits objectForKey:eachKey];
      if (KAHUNA_NOT_STRING_NULL_EMPTY (eachValue)) {
        // Check if this is a Kahuna credential key.
        if ([_kahunaCredentialsKeys containsObject:eachKey]) {
          [KahunaAnalytics setUserCredentialsWithKey:eachKey andValue:eachValue];
        } else {
          [attributes setValue:eachValue forKey:eachKey];
        }
      } else if ([eachValue isKindOfClass:[NSNumber class]]) {
        // Check if this is a Kahuna credential key.
        if ([_kahunaCredentialsKeys containsObject:eachKey]) {
          [KahunaAnalytics setUserCredentialsWithKey:eachKey andValue:[NSString stringWithFormat:@"%@", eachValue]];
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
    
    // Track the attributes if we have any items in it.
    if (attributes.count > 0) {
      [KahunaAnalytics setUserAttributes:attributes];
    }
  }
  @catch (NSException *exception) {
    NSLog (@"Kahuna-Segment Exception : %@", exception.description);
  }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
  @try {
    NSNumber *revenue = [self.class extractRevenue:properties];
    NSNumber *quantity = nil;
    for (NSString *key in properties) {
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
    
    // Get the count and value from quantity and revenue.
    long value = (long) ([revenue doubleValue] * 100);
    long count = [quantity longValue];
    
    if (count + value > 0) {
      [KahunaAnalytics trackEvent:event withCount:count andValue:value];
    } else {
      [KahunaAnalytics trackEvent:event];
    }
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *lowerCaseKeyProperties = [[NSMutableDictionary alloc] init];
    
    // Lower case all the keys and copy over the properties into a new dictionary.
    for (NSString *eachKey in properties) {
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
    if  (attributes.count > 0) {
      [KahunaAnalytics setUserAttributes:attributes];
    }
  }
  @catch (NSException *exception) {
    NSLog (@"Kahuna-Segment Exception : %@", exception.description);
  }
}

- (void) addViewedProductCategoryElements:(NSMutableDictionary*__autoreleasing*) attributes fromProperties:(NSDictionary*) properties {
  id value = properties [KAHUNA_CATEGORY];
  if (value && ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]])) {
    [(*attributes) setValue:value forKey:KAHUNA_LAST_VIEWED_CATEGORY];
    NSDictionary *existingAttributes = [KahunaAnalytics getUserAttributes];
    id categoriesViewed = [existingAttributes valueForKey:KAHUNA_CATEGORIES_VIEWED];
    if (categoriesViewed && [categoriesViewed isKindOfClass:[NSString class]]) {
      NSMutableArray *aryOfCategoriesViewed = [[categoriesViewed componentsSeparatedByString:@","] mutableCopy];
      if (![aryOfCategoriesViewed containsObject:value]) {
        if (aryOfCategoriesViewed.count > 50) {
          [aryOfCategoriesViewed removeObjectAtIndex:0];  // Remove the first object.
        }
        
        [aryOfCategoriesViewed addObject:value];
        [(*attributes) setValue:[aryOfCategoriesViewed componentsJoinedByString:@","] forKey:KAHUNA_CATEGORIES_VIEWED];
      }
    } else {
      [(*attributes) setValue:value forKey:KAHUNA_CATEGORIES_VIEWED];
    }
  } else {
    // Since we do not have a category, we will store "none" for last view category and categories viewed list.
    [(*attributes) setValue:KAHUNA_NONE forKey:KAHUNA_LAST_VIEWED_CATEGORY];
    [(*attributes) setValue:KAHUNA_NONE forKey:KAHUNA_CATEGORIES_VIEWED];
  }
}

- (void) addViewedProductElements:(NSMutableDictionary*__autoreleasing*) attributes fromProperties:(NSDictionary*) properties {
  id kname = properties [KAHUNA_NAME];
  if (KAHUNA_NOT_STRING_NULL_EMPTY(kname)) {
    [(*attributes) setValue:kname forKey:KAHUNA_LAST_PRODUCT_VIEWED_NAME];
  }
  
  [self addViewedProductCategoryElements:attributes fromProperties:properties];
}

- (void) addAddedProductElements:(NSMutableDictionary*__autoreleasing*) attributes fromProperties:(NSDictionary*) properties {
  id kname = properties [KAHUNA_NAME];
  if (KAHUNA_NOT_STRING_NULL_EMPTY(kname)) {
    [(*attributes) setValue:kname forKey:KAHUNA_LAST_PRODUCT_ADDED_TO_CART_NAME];
  }
  
  id category = properties [KAHUNA_CATEGORY];
  if (!KAHUNA_NOT_STRING_NULL_EMPTY(category)) {
    category = KAHUNA_NONE;
  }
  
  [(*attributes) setValue:category forKey:KAHUNA_LAST_PRODUCT_ADDED_TO_CART_CATEGORY];
}

- (void) addCompletedOrderElements:(NSMutableDictionary*__autoreleasing*) attributes fromProperties:(NSDictionary*) properties {
  id discount = properties [KAHUNA_DISCOUNT];
  if ([discount isKindOfClass:[NSString class]] || [discount isKindOfClass:[NSNumber class]]) {
    [(*attributes) setValue:discount forKey:KAHUNA_LAST_PURCHASE_DISCOUNT];
  } else {
    [(*attributes) setValue:@0 forKey:KAHUNA_LAST_PURCHASE_DISCOUNT];
  }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options {
  id trackAllPages = [self.settings objectForKey:@"trackAllPages"];
  if (trackAllPages &&
      [trackAllPages isKindOfClass:[NSNumber class]] &&
      [trackAllPages intValue] == 1 &&
      KAHUNA_NOT_STRING_NULL_EMPTY (screenTitle)) {
    // Track the screen view as an event.
    [self track:SEGEventNameForScreenTitle(screenTitle) properties:properties options:options];
  }
}

- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken options:(NSDictionary *)options {
  [KahunaAnalytics setDeviceToken:deviceToken];
}

- (void)reset {
  [KahunaAnalytics logout];
}

@end

// This class is responsible for getting the 'UIApplicationDidFinishLaunchingNotification' notification. It is received by the
// method didFinishLaunching and it calls [KahunaAnalytics handleNotification API.
@implementation KahunaPushMonitor

+ (instancetype) sharedInstance {
  static KahunaPushMonitor *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[KahunaPushMonitor alloc] init];
  });
  return instance;
}

- (void) didFinishLaunching:(NSNotification*) notificationPayload {
  @try {
    NSDictionary *userInfo = notificationPayload.userInfo;
    if ([userInfo valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
      NSDictionary *remoteNotification = [userInfo valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
      [KahunaPushMonitor sharedInstance].pushInfo = remoteNotification;
      [KahunaPushMonitor sharedInstance].applicationState = UIApplicationStateInactive;
    }
    
    // We will also swizzle the app delegate methods now. We need this so that we can intercept the registration for device token
    // and a push being received when the app is in foreground or background.
    [self swizzleAppDelegateMethods];
  }
  @catch (NSException *exception) {
    NSLog (@"Kahuna-Segment Exception : %@", exception.description);
  }
}

// App Delegate methods that deal with push notifications need to be swizzled here. That way this class will receive the delegate callbacks
// and access the necesary details from each callback.
- (void) swizzleAppDelegateMethods
{
  @try {
    // ####### didFailToRegisterForRemoteNotificationsWithError  #######
    SEL selector = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
    if ([[UIApplication sharedApplication].delegate respondsToSelector:selector])
    {
      selOriginalApplicationDidFailToRegisterForRemoteNotificationsWithError = (void (*)(id, SEL, id, id)) [[[UIApplication sharedApplication].delegate class] instanceMethodForSelector:selector];
    }
    else
    {
      Method methodSegmentWrapper = class_getInstanceMethod([self class], selector);
      const char *methodTypeEncoding = method_getTypeEncoding(methodSegmentWrapper);
      
      IMP implementationSegmentWrapper = class_getMethodImplementation([self class], selector);
      class_addMethod ([[UIApplication sharedApplication].delegate class], selector, implementationSegmentWrapper, methodTypeEncoding);
    }
    
    // ####### didReceiveRemoteNotification  #######
    selector = @selector(application:didReceiveRemoteNotification:);
    if ([[UIApplication sharedApplication].delegate respondsToSelector:selector])
    {
      selOriginalApplicationDidReceiveRemoteNotification = (void (*)(id, SEL, id, id)) [[[UIApplication sharedApplication].delegate class] instanceMethodForSelector:selector];
    }
    else
    {
      Method methodSegmentWrapper = class_getInstanceMethod([self class], selector);
      const char *methodTypeEncoding = method_getTypeEncoding(methodSegmentWrapper);
      
      IMP implementationSegmentWrapper = class_getMethodImplementation([self class], selector);
      class_addMethod ([[UIApplication sharedApplication].delegate class], selector, implementationSegmentWrapper, methodTypeEncoding);
    }
    
    // ####### didReceiveRemoteNotification:fetchCompletionHandler  #######
    selector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
    if ([[UIApplication sharedApplication].delegate respondsToSelector:selector])
    {
      selOriginalApplicationDidReceiveRemoteNotificationWithFetchCompletionHandler = (void (*)(id, SEL, id, id, void (^)(UIBackgroundFetchResult result))) [[[UIApplication sharedApplication].delegate class] instanceMethodForSelector:selector];
    }
    
    // ####### handleActionWithIdentifier:forRemoteNotification:completionHandler  #######
    selector = @selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:);
    if ([[UIApplication sharedApplication].delegate respondsToSelector:selector])
    {
      selOriginalApplicationHandleActionWithIdentifierWithFetchCompletionHandler = (void (*)(id, SEL, id, id, id, void(^)())) [[[UIApplication sharedApplication].delegate class] instanceMethodForSelector:selector];
    }
    else
    {
      Method methodSegmentWrapper = class_getInstanceMethod([self class], selector);
      const char *methodTypeEncoding = method_getTypeEncoding(methodSegmentWrapper);
      
      IMP implementationSegmentWrapper = class_getMethodImplementation([self class], selector);
      addedMethodHandleActionWithIdentifierWithFetchCompletionHandler = class_addMethod ([[UIApplication sharedApplication].delegate class], selector, implementationSegmentWrapper, methodTypeEncoding);
    }
    
    // Swizzle the methods only if we got the original Application selector. Otherwise no point doing the swizzling.
    Method methodSegmentWrapper = nil;
    Method methodHostApp = nil;
    
    // Swizzling didFailToRegisterForRemoteNotificationsWithError
    if (selOriginalApplicationDidFailToRegisterForRemoteNotificationsWithError)
    {
      methodSegmentWrapper = class_getInstanceMethod ([self class], @selector(application:didFailToRegisterForRemoteNotificationsWithError:));
      methodHostApp = class_getInstanceMethod ([[UIApplication sharedApplication].delegate class], @selector(application:didFailToRegisterForRemoteNotificationsWithError:));
      method_exchangeImplementations (methodSegmentWrapper, methodHostApp);
    }
    
    // Swizzling didReceiveRemoteNotification
    if(selOriginalApplicationDidReceiveRemoteNotification)
    {
      methodSegmentWrapper = class_getInstanceMethod ([self class], @selector(application:didReceiveRemoteNotification:));
      methodHostApp = class_getInstanceMethod ([[UIApplication sharedApplication].delegate class], @selector(application:didReceiveRemoteNotification:));
      method_exchangeImplementations (methodSegmentWrapper, methodHostApp);
    }
    
    if (selOriginalApplicationDidReceiveRemoteNotificationWithFetchCompletionHandler)
    {
      methodSegmentWrapper = class_getInstanceMethod ([self class], @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:));
      methodHostApp = class_getInstanceMethod ([[UIApplication sharedApplication].delegate class], @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:));
      method_exchangeImplementations (methodSegmentWrapper, methodHostApp);
    }
    
    selector = @selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:);
    if (selOriginalApplicationHandleActionWithIdentifierWithFetchCompletionHandler)
    {
      methodSegmentWrapper = class_getInstanceMethod ([self class], selector);
      methodHostApp = class_getInstanceMethod ([[UIApplication sharedApplication].delegate class], selector);
      method_exchangeImplementations (methodSegmentWrapper, methodHostApp);
    }
  }
  @catch (NSException *exception) {
    NSLog (@"Kahuna-Segment Exception : %@", exception.description);
  }
}

- (void) application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
  @try {
    if ([KahunaPushMonitor sharedInstance].kahunaInitialized) {
      [KahunaAnalytics handleNotificationRegistrationFailure:error];
    }
    
    if (selOriginalApplicationDidFailToRegisterForRemoteNotificationsWithError)
    {
      selOriginalApplicationDidFailToRegisterForRemoteNotificationsWithError ([UIApplication sharedApplication].delegate,
                                                                              @selector(application:didFailToRegisterForRemoteNotificationsWithError:),
                                                                              application,
                                                                              error);
    }
  }
  @catch (NSException *exception) {
    NSLog (@"Kahuna-Segment Exception : %@", exception.description);
  }
}

- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
  @try {
    [self pushReceived:userInfo];
    if (selOriginalApplicationDidReceiveRemoteNotification)
    {
      selOriginalApplicationDidReceiveRemoteNotification ([UIApplication sharedApplication].delegate,
                                                          @selector(application:didReceiveRemoteNotification:),
                                                          application,
                                                          userInfo);
    }
  }
  @catch (NSException *exception) {
    NSLog (@"Kahuna-Segment Exception : %@", exception.description);
  }
}

- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^) (UIBackgroundFetchResult result))completionHandler
{
  @try {
    [self pushReceived:userInfo];
    if (selOriginalApplicationDidReceiveRemoteNotificationWithFetchCompletionHandler)
    {
      selOriginalApplicationDidReceiveRemoteNotificationWithFetchCompletionHandler ([UIApplication sharedApplication].delegate,
                                                                                    @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:),
                                                                                    application,
                                                                                    userInfo,
                                                                                    completionHandler);
    }
  }
  @catch (NSException *exception) {
    NSLog (@"Kahuna-Segment Exception : %@", exception.description);
  }
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler
{
  @try {
    [self pushReceived:userInfo];
    if (selOriginalApplicationHandleActionWithIdentifierWithFetchCompletionHandler)
    {
      selOriginalApplicationHandleActionWithIdentifierWithFetchCompletionHandler ([UIApplication sharedApplication].delegate,
                                                                                  @selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:),
                                                                                  application,
                                                                                  identifier,
                                                                                  userInfo,
                                                                                  completionHandler);
    } else {
      if (addedMethodHandleActionWithIdentifierWithFetchCompletionHandler) {
        completionHandler ();
      }
    }
  }
  @catch (NSException *exception) {
    NSLog (@"Kahuna-Segment Exception : %@", exception.description);
  }
}

- (void) pushReceived:(NSDictionary*) userInfo {
  // When we get this notification, check if kahuna is initialized. If not store it for future use.
  if ([KahunaPushMonitor sharedInstance].kahunaInitialized) {
    [KahunaAnalytics handleNotification:userInfo withApplicationState:[UIApplication sharedApplication].applicationState];
  } else {
    [KahunaPushMonitor sharedInstance].pushInfo = userInfo;
    [KahunaPushMonitor sharedInstance].applicationState = [UIApplication sharedApplication].applicationState;
  }
}

@end