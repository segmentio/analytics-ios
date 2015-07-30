
// KahunaIntegration.h
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Foundation/Foundation.h>
#import "SEGAnalyticsIntegration.h"


@interface SEGKahunaIntegration : SEGAnalyticsIntegration {
    NSSet *_kahunaCredentialsKeys;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) BOOL valid;
@property (nonatomic, assign) BOOL initialized;
@property (nonatomic, copy) NSDictionary *settings;
@property Class kahunaClass;

@end


@interface SEGKahunaPushMonitor : NSObject
@property (atomic) NSDictionary *pushInfo;
@property (atomic) UIApplicationState applicationState;
@property (atomic) BOOL kahunaInitialized;
@property (atomic) NSError *failedToRegisterError;
@property Class kahunaClass;

+ (instancetype)sharedInstance;
- (void)didFinishLaunching:(NSNotification *)userInfo;

@end
