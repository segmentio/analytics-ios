//
//  SEGState.h
//  Analytics
//
//  Created by Brandon Sneed on 6/9/20.
//  Copyright © 2020 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SEGUserInfo: NSObject
@property (nonatomic, readonly, nonnull) NSString *anonymousId;
@property (nonatomic, readonly, nullable) NSString *userId;
@property (nonatomic, readonly, nullable) NSDictionary *traits;
@end


@interface SEGState : NSObject

@property (nonatomic, readonly, nonnull) SEGUserInfo *userInfo;

+ (instancetype)sharedInstance;
- (instancetype)init __unavailable;

- (void)setUserInfo:(SEGUserInfo *)userInfo;
@end

NS_ASSUME_NONNULL_END
