//
//  SEGMoEngageIntegration.h
//  Analytics
//
//  Created by Gautam on 28/05/15.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import "SEGAnalyticsIntegration.h"


@interface SEGMoEngageIntegration : SEGAnalyticsIntegration

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) BOOL valid;
@property (nonatomic, assign) BOOL initialized;
@property (nonatomic, copy) NSDictionary *settings;

@end


@interface SEGMoEngagePushManager : NSObject

@property (nonatomic) NSDictionary *pushInfoDict;
@property (nonatomic) BOOL moengageInitialized;

+ (instancetype)sharedInstance;

@end
