//
//  AnalyticsSettingsCacheTest.m
//
//  Created by Peter Reinhardt on 5/13/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "SettingsCache.h"
#import "GHUnit.h"


@interface AnalyticsSettingsCacheTest : GHAsyncTestCase
@property(nonatomic) SettingsCache *settingsCache;
@end




@implementation AnalyticsSettingsCacheTest

- (void)onSettingsUpdate:(NSDictionary *)settings
{
    [self notify:kGHUnitWaitStatusSuccess];
}

- (void)setUp
{
    [super setUp];
    self.settingsCache = [SettingsCache sharedSettingsCacheWithSecret:@"testsecret" delegate:self];
}

- (void)tearDown
{
    [super tearDown];
    self.settingsCache = nil;
}

#pragma mark - Settings Cache

- (void)testInit
{
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}

@end