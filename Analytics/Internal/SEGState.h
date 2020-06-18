//
//  SEGState.h
//  Analytics
//
//  Created by Brandon Sneed on 6/9/20.
//  Copyright © 2020 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SEGAnalyticsConfiguration;

@interface SEGUserInfo: NSObject
@property (nonatomic, strong, nonnull) NSString *anonymousId;
@property (nonatomic, strong, nullable) NSString *userId;
@property (nonatomic, strong, nullable) NSDictionary *traits;
@end

@interface SEGPayloadContext: NSObject
@property (nonatomic, readonly, nonnull) NSDictionary *payload;
@property (nonatomic, strong, nullable) NSDictionary *referrer;
@property (nonatomic, strong, nullable) NSString *deviceToken;

- (void)updateStaticContext;

@end



@interface SEGState : NSObject

@property (nonatomic, readonly, nonnull) SEGUserInfo *userInfo;
@property (nonatomic, readonly, nonnull) SEGPayloadContext *context;

@property (nonatomic, nullable) SEGAnalyticsConfiguration *configuration;

+ (instancetype)sharedInstance;
- (instancetype)init __unavailable;

- (void)setUserInfo:(SEGUserInfo *)userInfo;
@end

NS_ASSUME_NONNULL_END
