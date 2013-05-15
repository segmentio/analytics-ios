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
    self.settingsCache = [SettingsCache withSecret:@"testsecret" delegate:self];
}

- (void)tearDown
{
    [super tearDown];
    [self.settingsCache clear];
    self.settingsCache = nil;
}

#pragma mark - Settings Cache

- (void)testInit
{
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];
    
    [self.settingsCache update];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}

- (void)testCacheBehavior
{
    [self.settingsCache clear];
    self.settingsCache = nil;
    
    self.settingsCache = [SettingsCache withSecret:@"testsecret" delegate:self];
    
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];
    
    NSDictionary *settings = [self.settingsCache getSettings];
    NSLog(@"%@ settings should be null", settings);
    GHAssertNil(settings, @"Settings dictionary should be nil after getting cleared.");
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
    
    settings = [self.settingsCache getSettings];
    NSLog(@"%d count", [settings count]);
    GHAssertEquals([settings count], (NSUInteger)18, @"Settings dictionary did not have expected number of providers.");
    
    // Destroy this cache
    self.settingsCache = nil;
    
    // Create a new cache, it should immediately have the full settings, which we'll clear, and then wait 30 seconds to see
    self.settingsCache = [SettingsCache withSecret:@"testsecret" delegate:self];
    
    settings = [self.settingsCache getSettings];
    NSLog(@"%d count", [settings count]);
    GHAssertEquals([settings count], (NSUInteger)18, @"Settings dictionary did not have expected number of providers.");
    
    // wait for the refresh
    [self prepare];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:40.0];
    
    // verify we still have everything
    settings = [self.settingsCache getSettings];
    NSLog(@"%d count", [settings count]);
    GHAssertEquals([settings count], (NSUInteger)18, @"Settings dictionary did not have expected number of providers.");
}

- (void)testGetSettings
{
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];
    
    [self.settingsCache update];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
    
    NSDictionary *settings = [self.settingsCache getSettings];
    NSLog(@"%d count", [settings count]);
    GHAssertEquals([settings count], (NSUInteger)18, @"Settings dictionary did not have expected number of providers.");
}

- (void)testSettingsParsed
{
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];
    
    [self.settingsCache update];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
    
    NSDictionary *settings = [self.settingsCache getSettings];
    
    // Chartbeat settings
    NSDictionary *chartbeat = [settings objectForKey:@"Chartbeat"];
    GHAssertEqualObjects([chartbeat valueForKey:@"apiKey"], @"TEST", @"Settings for Chartbeat did not match apikey:TEST.");
    
    // Google Analytics settings
    NSDictionary *google = [settings objectForKey:@"Google Analytics"];
    GHAssertEqualObjects([google valueForKey:@"trackingId"], @"UA-27033709-9", @"Settings for Google Analytics did not match token:UA-27033709-9.");
    
    // Mixpanel settings
    NSDictionary *mixpanel = [settings objectForKey:@"Mixpanel"];
    GHAssertEquals([[mixpanel objectForKey:@"people"] integerValue], (NSInteger)1, @"Settings for Mixpanel did not match people:1.");
    GHAssertEqualObjects([mixpanel valueForKey:@"token"], @"89f86c4aa2ce5b74cb47eb5ec95ad1f9", @"Settings for Mixpanel did not match token:89f86c4aa2ce5b74cb47eb5ec95ad1f9.");
}

- (void)testClear
{
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];
    
    [self.settingsCache update];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
    
    [self.settingsCache clear];
    
    NSDictionary *settings = [self.settingsCache getSettings];
    NSLog(@"%@ settings should be null", settings);
    GHAssertNil(settings, @"Settings dictionary should be nil after getting cleared.");
}

@end