//
//  KWNotificationMatcher.m
//  CLToolkit
//
//  Created by Tony Xiao on 8/24/13.
//  Copyright (c) 2013 Collections Labs, Inc. All rights reserved.
//

#import <Kiwi/KWMessageTracker.h>
#import "KWNotificationMatcher.h"

@implementation KWNotificationMatcher {
    KWMessageTracker *_messageTracker;
	NSString *_notificationName;
}

- (void)addObserver:(NSString *)notificationName countType:(KWCountType)aCountType count:(NSUInteger)aCount userInfo:(NSDictionary *)userInfo {
	if (![self.subject isKindOfClass:[NSNotificationCenter class]])
		[NSException raise:@"KWMatcherException" format:@"subject is not of type -NSNotificationCenter"];

	_notificationName = notificationName;
    
    NSArray *filters = userInfo ? @[[KWBlockMatchEvaluator evaluatorWithBlock:^BOOL(NSNotification *note) {
        return [note.userInfo isEqual:userInfo];
    }]] : nil;
	KWMessagePattern *mp = [KWMessagePattern messagePatternWithSelector:@selector(handleNotification:)
                                                        argumentFilters:filters];
	[self.subject addObserver:self
                     selector:@selector(handleNotification:)
                         name:_notificationName
                       object:nil];
    _messageTracker = [KWMessageTracker messageTrackerWithSubject:self
                                                   messagePattern:mp
                                                        countType:aCountType
                                                            count:aCount];
}

- (void)handleNotification:(NSNotification *)notification { }

#pragma mark - Public API

- (void)receiveNotification:(NSString *)name {
	return [self addObserver:name countType:KWCountTypeExact count:1 userInfo:nil];
}

- (void)receiveNotification:(NSString *)name withCount:(NSUInteger)aCount {
	return [self addObserver:name countType:KWCountTypeExact count:aCount userInfo:nil];
}

- (void)receiveNotification:(NSString *)name withCountAtLeast:(NSUInteger)aCount {
	return [self addObserver:name countType:KWCountTypeAtLeast count:aCount userInfo:nil];
}

- (void)receiveNotification:(NSString *)name withCountAtMost:(NSUInteger)aCount {
	return [self addObserver:name countType:KWCountTypeAtMost count:aCount userInfo:nil];
}

- (void)receiveNotification:(NSString *)name withUserInfo:(NSDictionary *)userInfo {
	return [self addObserver:name countType:KWCountTypeExact count:1 userInfo:userInfo];
}

- (void)receiveNotification:(NSString *)name withCount:(NSUInteger)aCount userInfo:(NSDictionary *)userInfo {
	return [self addObserver:name countType:KWCountTypeExact count:aCount userInfo:userInfo];
}

- (void)receiveNotification:(NSString *)name withCountAtLeast:(NSUInteger)aCount userInfo:(NSDictionary *)userInfo {
	return [self addObserver:name countType:KWCountTypeAtLeast count:aCount userInfo:userInfo];
}

- (void)receiveNotification:(NSString *)name withCountAtMost:(NSUInteger)aCount userInfo:(NSDictionary *)userInfo {
	return [self addObserver:name countType:KWCountTypeAtMost count:aCount userInfo:userInfo];
}

#pragma mark - KWMatcher Requirements

- (NSString *)failureMessageForShould {
    return $str(@"expected subject to send notification -%@ %@, but received it %@",
                [_messageTracker expectedCountPhrase],
                _notificationName,
                [_messageTracker receivedCountPhrase]);
}

- (NSString *)failureMessageForShouldNot {
    return $str(@"expected subject not to send notification -%@, but received it %@",
                _notificationName,
                [_messageTracker receivedCountPhrase]);
}

- (BOOL)evaluate {
	BOOL succeeded = [_messageTracker succeeded];
	[_messageTracker stopTracking];
	[self.subject removeObserver:self];
	return succeeded;
}

- (BOOL)shouldBeEvaluatedAtEndOfExample {
	return YES;
}

+ (NSArray *)matcherStrings {
    return @[
        NSStringFromSelector(@selector(receiveNotification:)),
        NSStringFromSelector(@selector(receiveNotification:withCount:)),
        NSStringFromSelector(@selector(receiveNotification:withCountAtLeast:)),
        NSStringFromSelector(@selector(receiveNotification:withCountAtMost:)),
        NSStringFromSelector(@selector(receiveNotification:withUserInfo:)),
        NSStringFromSelector(@selector(receiveNotification:withCount:userInfo:)),
        NSStringFromSelector(@selector(receiveNotification:withCountAtLeast:userInfo:)),
        NSStringFromSelector(@selector(receiveNotification:withCountAtMost:userInfo:))
    ];
}

@end
