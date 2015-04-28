
// KahunaIntegration.h
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Foundation/Foundation.h>
#import "SEGAnalyticsIntegration.h"

@interface SEGKahunaIntegration : SEGAnalyticsIntegration {
    NSSet *_kahunaCredentialsKeys;
}

@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) BOOL valid;
@property(nonatomic, assign) BOOL initialized;
@property(nonatomic, copy) NSDictionary *settings;

@end

@interface KahunaPushMonitor : NSObject
@property (nonatomic) NSDictionary *pushInfo;
@property (nonatomic) UIApplicationState applicationState;
@property (nonatomic) BOOL kahunaInitialized;

+ (instancetype) sharedInstance;
- (void) didFinishLaunching:(NSNotification*) userInfo;

@end
