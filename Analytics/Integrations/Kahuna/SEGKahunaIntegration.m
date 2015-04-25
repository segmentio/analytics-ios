// KahunaIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import "SEGKahunaIntegration.h"
#import "KahunaAnalytics.h"
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"

#define KAHUNA_NOT_STRING_NULL_EMPTY(obj) (obj != nil \
&& [obj isKindOfClass:[NSString class]] \
&& ![@"" isEqualToString:obj])


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
static NSString* const KAHUNA_NONE = @"none";

@implementation SEGKahunaIntegration
@synthesize initialized, valid, name, settings;

#pragma mark - Initialization

+ (void)load {
  [SEGAnalytics registerIntegration:self withIdentifier:@"Kahuna"];
  
  // When this class loads we will register for the 'UIApplicationDidFinishLaunchingNotification' notification.
  // To receive the notification we will use the KahunaAppLaunchMonitor singleton instance.
  [[NSNotificationCenter defaultCenter] addObserver:[KahunaAppLaunchMonitor sharedInstance]
                                           selector:@selector(didFinishLaunching:)
                                               name:UIApplicationDidFinishLaunchingNotification
                                             object:nil];
  
  [KahunaAnalytics setDeepIntegrationMode:true];    // Creating Kahuna on the main thread and enabling deep integration mode.
                                                    // This ensures Kahuna's LocationManager is created on the main thread.
}

- (id)init {
  if (self = [super init]) {
    self.name = @"Kahuna";
    self.valid = NO;
    self.initialized = NO;
  }
  return self;
}

- (void)start {
  [KahunaAnalytics launchWithKey:[self.settings objectForKey:@"apiKey"]];
  [super start];
}


#pragma mark - Settings

- (void)validate {
  self.valid = [self.settings objectForKey:@"apiKey"] != nil;
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {
  NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
  if (KAHUNA_NOT_STRING_NULL_EMPTY (userId)) {
    [KahunaAnalytics setUserCredentialsWithKey:KAHUNA_CREDENTIAL_USER_ID andValue:userId];
  }
  
  // Try to extract the following keys from the traits.
  NSSet *kahunaCredentialsKeys = [NSSet setWithObjects:       KAHUNA_CREDENTIAL_USERNAME,
                                                              KAHUNA_CREDENTIAL_EMAIL,
                                                              KAHUNA_CREDENTIAL_FACEBOOK,
                                                              KAHUNA_CREDENTIAL_TWITTER,
                                                              KAHUNA_CREDENTIAL_LINKEDIN,
                                                              KAHUNA_CREDENTIAL_USER_ID,
                                                              KAHUNA_CREDENTIAL_GOOGLE_PLUS,
                                                              KAHUNA_CREDENTIAL_INSTALL_TOKEN, nil];
  
  
  // We will go through each of the above keys, and try to see if the traits has that key. If it does, then we will add the key:value as a credential.
  // All other traits is being tracked as an attribute.
  for (NSString *eachKey in traits) {
    if (!KAHUNA_NOT_STRING_NULL_EMPTY (eachKey)) continue;
    
    NSString *eachValue = [traits objectForKey:eachKey];
    if (KAHUNA_NOT_STRING_NULL_EMPTY (eachValue)) {
      // Check if this is a Kahuna credential key.
      if ([kahunaCredentialsKeys containsObject:eachKey]) {
        [KahunaAnalytics setUserCredentialsWithKey:eachKey andValue:eachValue];
      } else {
        [attributes setValue:eachValue forKey:eachKey];
      }
    } else if ([eachValue isKindOfClass:[NSNumber class]]) {
      // Check if this is a Kahuna credential key.
      if ([kahunaCredentialsKeys containsObject:eachKey]) {
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
  attributes = nil;
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
      NSSet *setOfCategoriesViewed = [NSSet setWithArray:aryOfCategoriesViewed];
      if (![setOfCategoriesViewed containsObject:value]) {
        [aryOfCategoriesViewed addObject:value];
        if (aryOfCategoriesViewed.count > 50) {
          [(*attributes) setValue:[[aryOfCategoriesViewed subarrayWithRange:NSMakeRange (0,50)] componentsJoinedByString:@","] forKey:KAHUNA_CATEGORIES_VIEWED];
        } else {
          [(*attributes) setValue:[aryOfCategoriesViewed componentsJoinedByString:@","] forKey:KAHUNA_CATEGORIES_VIEWED];
        }
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
  id name = properties [KAHUNA_NAME];
  if (KAHUNA_NOT_STRING_NULL_EMPTY(name)) {
    [(*attributes) setValue:name forKey:KAHUNA_LAST_PRODUCT_VIEWED_NAME];
  }
  
  [self addViewedProductCategoryElements:attributes fromProperties:properties];
}

- (void) addAddedProductElements:(NSMutableDictionary*__autoreleasing*) attributes fromProperties:(NSDictionary*) properties {
  id name = properties [KAHUNA_NAME];
  if (KAHUNA_NOT_STRING_NULL_EMPTY(name)) {
    [(*attributes) setValue:name forKey:KAHUNA_LAST_PRODUCT_ADDED_TO_CART_NAME];
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
  if (KAHUNA_NOT_STRING_NULL_EMPTY (screenTitle)) {
    // Track the screen view as an event.
    [self track:SEGEventNameForScreenTitle(screenTitle) properties:properties options:options];
  }
}

- (void)alias:(NSString *)newId options:(NSDictionary *)options {
  if (KAHUNA_NOT_STRING_NULL_EMPTY (newId)) {
    [KahunaAnalytics setUserCredentialsWithKey:KAHUNA_CREDENTIAL_USER_ID andValue:newId];
  }
}

- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken options:(NSDictionary *)options {
  // Do nothing, since we are already taking care of this using deep integration.
}

- (void)reset {
  [KahunaAnalytics logout];
}

@end

// This class is responsible for getting the 'UIApplicationDidFinishLaunchingNotification' notification. It is received by the
// method didFinishLaunching and it calls [KahunaAnalytics handleNotification API.
@implementation KahunaAppLaunchMonitor

+ (instancetype) sharedInstance {
  static KahunaAppLaunchMonitor *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[KahunaAppLaunchMonitor alloc] init];
  });
  return instance;
}

- (void) didFinishLaunching:(NSNotification*) notificationPayload {
  NSDictionary *userInfo = notificationPayload.userInfo;
  if ([userInfo valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
    NSDictionary *remoteNotification = [userInfo valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    [KahunaAnalytics handleNotification:remoteNotification withApplicationState:UIApplicationStateInactive];
  }
}

@end