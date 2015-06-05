//
//  SEGTaplytics.m
//  Analytics
//
//  Created by Travis Jeffery on 6/4/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import "SEGTaplyticsIntegration.h"
#import "SEGAnalytics.h"
#import "SEGAnalyticsUtils.h"

#import <Taplytics/Taplytics.h>

@implementation SEGTaplyticsIntegration

+ (void)load {
  [SEGAnalytics registerIntegration:self withIdentifier:[self identifier]];
}

- (id)init {
  if (self = [super init]) {
    self.name = [self.class identifier];
    self.valid = NO;
    self.initialized = NO;
  }
  return self;
}

- (void)start {
  NSDictionary *options = [[NSMutableDictionary alloc] init];
  
  if ([self delayLoad])
      [options setValue:[self delayLoad] forKey:@"delayLoad"];
  
  if ([self shakeMenu])
      [options setValue:[self shakeMenu] forKey:@"shakeMenu"];
  
  [Taplytics startTaplyticsAPIKey:[self apiKey] options:options];
  
  SEGLog(@"TaplyticsIntegration initialized with api key %@ and options %@", [self apiKey], options);
  [super start];
}

- (void)validate {
  self.valid = ([self apiKey] != nil);
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {
    // Map the traits to special mixpanel keywords.
    NSDictionary* map = @{
      @"lastName": @"lastName",
      @"firstName": @"firstName",
      @"gender": @"gender",
      @"age": @"age",
      @"name": @"name",
      @"email": @"email",
      @"avatarURl": @"avatar"
    };
    
    NSMutableDictionary *mappedTraits = [NSMutableDictionary dictionaryWithDictionary:[SEGAnalyticsIntegration map:traits withMap:map]];
    mappedTraits[@"user_id"] = userId;
    
    [Taplytics setUserAttributes:mappedTraits];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
    // If revenue is included, logRevenue to Taplytics.
    NSNumber *revenue = [SEGAnalyticsIntegration extractRevenue:properties];
    if (revenue) {
        [Taplytics logRevenue:event revenue:revenue metaData:properties];
    }
    else {
        [Taplytics logEvent:event value:nil metaData:properties];
    }
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options {
    NSMutableDictionary *userAttributes = [[NSMutableDictionary alloc] init];
    
    if (groupId && [groupId length] > 0)
        [userAttributes setObject:groupId forKey:@"groupId"];
    
    if (traits && [[traits allKeys] count] > 0)
        [userAttributes setObject:traits forKey:@"groupTraits"];
    
    if (userAttributes.count > 0)
        [Taplytics setUserAttributes:userAttributes];
};

- (void)reset {
    [Taplytics resetUser:^{
        SEGLog(@"Reset Taplytics User");
    }];
}

#pragma mark - Private

- (NSString *)apiKey {
  return self.settings[@"apiKey"];
}

- (NSNumber *)delayLoad {
    NSString *value = self.settings[@"delayLoad"];
    
    if (value != nil)
        return [NSNumber numberWithInt:[value intValue]];
    
    return nil;
}

- (NSNumber *)shakeMenu {
    NSString *value = self.settings[@"shakeMenu"];
    
    if (value != nil)
        return [NSNumber numberWithBool:[value boolValue]];
    
    return nil;
}

+ (NSString *)identifier {
  return @"Taplytics";
}

@end
