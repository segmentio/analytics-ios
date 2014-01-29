//
//  KWNotificationMatcher.h
//  CLToolkit
//
//  Created by Tony Xiao on 8/24/13.
//  Copyright (c) 2013 Collections Labs, Inc. All rights reserved.
//
// Adopted from and credit goes to https://gist.github.com/MattesGroeger/4066084

#import <Kiwi/KWMatcher.h>

@interface KWNotificationMatcher : KWMatcher

- (void)receiveNotification:(NSString *)name;
- (void)receiveNotification:(NSString *)name withCount:(NSUInteger)aCount;
- (void)receiveNotification:(NSString *)name withCountAtLeast:(NSUInteger)aCount;
- (void)receiveNotification:(NSString *)name withCountAtMost:(NSUInteger)aCount;

- (void)receiveNotification:(NSString *)name withUserInfo:(NSDictionary *)userInfo;
- (void)receiveNotification:(NSString *)name withCount:(NSUInteger)aCount userInfo:(NSDictionary *)userInfo;
- (void)receiveNotification:(NSString *)name withCountAtLeast:(NSUInteger)aCount userInfo:(NSDictionary *)userInfo;
- (void)receiveNotification:(NSString *)name withCountAtMost:(NSUInteger)aCount userInfo:(NSDictionary *)userInfo;

@end
