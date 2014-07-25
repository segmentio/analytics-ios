// SegmentioTests.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <XCTest/XCTest.h>
#import <Expecta/Expecta.h>
#import "SEGAnalytics.h"
#import "SEGAnalyticsUtils.h"
#import "SEGSegmentioIntegration.h"
#import <TRVSKit/TRVSAssertions.h>

@interface SEGSegmentioIntegration (Private)
@property (nonatomic, readonly) NSMutableArray *queue;
@property (nonatomic, readonly) NSMutableDictionary *context;
@end

@interface SegmentioIntegrationDevelopment : SEGSegmentioIntegration

@end

@implementation SegmentioIntegrationDevelopment

- (id)initWithConfiguration:(SEGAnalyticsConfiguration *)configuration {
  if (self = [super initWithConfiguration:configuration]) {
    self.apiURL = [[NSURL alloc] initWithString:@"http://localhost:7001/v1/import"];
  }
  return self;
}

@end

@interface SEGSegmentioIntegrationTests : XCTestCase

@property (nonatomic, strong) SEGSegmentioIntegration *integration;

@end

@implementation SEGSegmentioIntegrationTests

- (void)setUp {
  [super setUp];
  
  if ([self isCI]) {
    SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"testWriteKey"];
    configuration.flushAt = 1;
    self.integration = [[SEGSegmentioIntegration alloc] initWithConfiguration:configuration];
  } else {
    SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"bvbqrhaeg4"];
    configuration.flushAt = 1;
    self.integration = [[SegmentioIntegrationDevelopment alloc] initWithConfiguration:configuration];
  }
}

- (void)tearDown {
  [super tearDown];

  [self.integration reset];
}

- (void)testAnonymousIdIsPresent {
  XCTAssertNotNil(self.integration.anonymousId);
}

- (void)testTrackAddsToQueue {
  self.integration.configuration.flushAt = 2;

  [self.integration track:self.event properties:self.properties options:self.options];

  EXP_expect(self.integration.queue.count).will.equal(1);
}

- (void)testTrackRequestData {
  self.integration.configuration.flushAt = 2;
  [self.integration track:self.event properties:self.properties options:self.options];

  EXP_expect(self.integration.queue.count).will.equal(1);
  NSDictionary *msg = self.integration.queue.firstObject;
  XCTAssertEqualObjects(@"track", msg[@"type"]);
  XCTAssertEqualObjects(self.event, msg[@"event"]);
  XCTAssertNotNil(msg[@"timestamp"]);
  XCTAssertNotNil(msg[@"properties"]);
  XCTAssertEqualObjects(self.properties, msg[@"properties"]);
  XCTAssertEqualObjects(self.options[@"integrations"], msg[@"integrations"]);

  NSDictionary *context = msg[@"context"];
  XCTAssertNotNil(context[@"library"][@"name"]);
  XCTAssertNotNil(context[@"library"][@"version"]);
  XCTAssertNotNil(context[@"device"][@"manufacturer"]);
  XCTAssertNotNil(context[@"device"][@"model"]);
  XCTAssertNotNil(context[@"os"][@"name"]);
  XCTAssertNotNil(context[@"os"][@"version"]);
  XCTAssertNotNil(context[@"screen"][@"width"]);
}

- (void)testTrackPostsRequestNotifications {
  if ([self isCI]) return;
  
  trvs_assertNotificationsObserved(self, ^{
    [self.integration track:self.event properties:self.properties options:self.options];
  }, SEGSegmentioDidSendRequestNotification, SEGSegmentioRequestDidSucceedNotification, nil);
}

- (void)testIdentifyAddsToQueue {
  self.integration.configuration.flushAt = 2;

  [self.integration identify:self.identity traits:self.traits options:self.options];

  EXP_expect(self.integration.queue.count).will.equal(1);
}

- (void)testIdentifyRequestData {
  self.integration.configuration.flushAt = 2;
  [self.integration identify:self.identity traits:self.traits options:self.options];

  EXP_expect(self.integration.queue.count).will.equal(1);
  NSDictionary *msg = self.integration.queue.firstObject;
  XCTAssertEqualObjects(@"identify", msg[@"type"]);
  XCTAssertEqualObjects(self.identity, msg[@"userId"]);
  XCTAssertNotNil(msg[@"timestamp"]);
  XCTAssertNotNil(msg[@"anonymousId"]);
  XCTAssertEqualObjects(self.traits, msg[@"traits"]);
  XCTAssertEqualObjects(self.options[@"integrations"], msg[@"integrations"]);

  NSDictionary *context = msg[@"context"];
  XCTAssertNotNil(context[@"library"][@"name"]);
  XCTAssertNotNil(context[@"library"][@"version"]);
  XCTAssertNotNil(context[@"device"][@"manufacturer"]);
  XCTAssertNotNil(context[@"device"][@"model"]);
  XCTAssertNotNil(context[@"os"][@"name"]);
  XCTAssertNotNil(context[@"os"][@"version"]);
  XCTAssertNotNil(context[@"screen"][@"width"]);
}

- (void)testIdentifyPostsRequestNotifications {
  if ([self isCI]) return;
  
  trvs_assertNotificationsObserved(self, ^{
    [self.integration identify:self.identity traits:self.traits options:self.options];
  }, SEGSegmentioDidSendRequestNotification, SEGSegmentioRequestDidSucceedNotification, nil);
}

- (void)testReset {
  self.integration.configuration.flushAt = 2;
  trvs_assertNotificationsNotObserved(self, ^{
    [self.integration track:self.event properties:self.properties options:self.options];

    NSString *anonymousId = self.integration.anonymousId;

    [self.integration reset];

    EXP_expect(self.integration.queue.count).will.equal(0);
    XCTAssertNotEqualObjects(anonymousId, self.integration.anonymousId);
  }, SEGSegmentioRequestDidSucceedNotification, SEGSegmentioDidSendRequestNotification, nil);
}

#pragma mark - Private

- (NSString *)event {
  return @"some event";
}

- (NSDictionary *)properties {
  return @{ @"category": @"Mobile" };
}

- (NSString *)identity {
  return @"some user";
}

- (NSDictionary *)traits {
  return @{ @"FriendCount": @223 };
}

- (NSDictionary *)options {
  return @{ @"integrations": @{ @"Salesforce": @YES, @"HubSpot": @NO } };
}

- (BOOL)isCI {
  return [NSProcessInfo.processInfo.environment objectForKey:@"CI"] != nil;
}

@end
