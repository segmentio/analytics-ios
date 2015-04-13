// SEGLeanplumIntegration.m
// Created by Scott Snibbe

#import "SEGLeanplumIntegration.h"
#import <Leanplum/Leanplum.h>
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"

@implementation SEGLeanplumIntegration

#pragma mark - Initialization

+ (void)load {
    [SEGAnalytics registerIntegration:self withIdentifier:@"Leanplum"];
}

- (id)init {
    if (self = [super init]) {
        self.name = @"Leanplum";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start {
    
    [Leanplum setAppId:[self appId]
    withDevelopmentKey:[self devKey]];
    
    SEGLog(@"Leanplum: setup with appId: %@, devKey: %@", [self appId], [self devKey]);
    
    [Leanplum start];
    
    [Leanplum onVariablesChanged:^() {  // this makes sure changes to variables and resources update
        // nothing
    }];
    
    [super start];
}

#pragma mark - Settings

- (void)validate {
    self.valid = ([self devKey] != nil && [self appId] != nil);
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {
    if (userId != nil && [userId length] != 0)
        
        [Leanplum setUserId:userId];
    [Leanplum setUserAttributes:traits];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
    // Only track the event if it isn't blocked
    if (![self eventIsBlocked:event]) {
        // Track the raw event.
        [Leanplum track:event withParameters:properties];
    }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options {
    // Track the screen view as an event.
    [self track:SEGEventNameForScreenTitle(screenTitle) properties:properties options:options];
}

- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken options:(NSDictionary *)options {
    // not sure
}

- (BOOL)eventShouldIncrement:(NSString *)event {
    NSArray *increments = [self.settings objectForKey:@"increments"];
    for (NSString *increment in increments) {
        if ([event caseInsensitiveCompare:increment] == NSOrderedSame) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)eventIsBlocked:(NSString *)event {
    NSArray *blocked = [self.settings objectForKey:@"blockedEvents"];
    for (NSString *block in blocked) {
        if ([event caseInsensitiveCompare:block] == NSOrderedSame) {
            return YES;
        }
    }
    return NO;
}

- (void)reset {
    // nothing
}

- (NSString *)devKey {
    return self.settings[@"leanPlumDevKey"];
}

- (NSString *)appId {
    return self.settings[@"leanPlumAppID"];
}

@end
