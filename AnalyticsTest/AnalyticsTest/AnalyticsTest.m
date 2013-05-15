//
//  SegmentioTest.m
//
//  Created by Peter Reinhardt on 4/10/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "Analytics.h"
#import "ProviderManager.h"
#import "SettingsCache.h"
#import "GHUnit.h"



// get access to private members
@interface Analytics (Test)
@property(nonatomic, strong) NSString *secret;
@property(nonatomic, strong) ProviderManager *providerManager;
@end

@interface ProviderManager (Test)
@property(nonatomic, strong) NSString *secret;
@end


@interface AnalyticsTest : GHAsyncTestCase
@property(nonatomic) Analytics *analytics;
@end


@implementation AnalyticsTest

- (void)setUp
{
    [super setUp];
    self.analytics = [Analytics withSecret:@"testsecret"];
}

- (void)tearDown
{
    [super tearDown];
    self.analytics = nil;
}

#pragma mark - Core

- (void)testSecret
{
    GHAssertEqualObjects(self.analytics.secret, @"testsecret", @"Analytics secret was not set to testsecret.");
    
    ProviderManager *providerManager = self.analytics.providerManager;
    GHAssertEqualObjects(providerManager.secret, @"testsecret", @"ProviderManager secret was not set to testsecret.");
}


#pragma mark - API Methods

- (void)testTrack
{
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];
    
    NSString *eventName = @"Purchased an iPad 5";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: @"testvalue", @"testkey", nil];
    [self.analytics track:eventName properties:properties context:context];
    
}

- (void)testIdentify
{
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];
    
    NSString *userId = @"smile@wrinkledhippo.com";
    NSDictionary *traits = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: @"testvalue", @"testkey", nil];
    [self.analytics identify:userId traits:traits context:context];
    
}

@end