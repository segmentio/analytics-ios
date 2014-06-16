// AnalyticsTests.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <XCTest/XCTest.h>

#import "SEGAnalytics.h"
#import "SEGSegmentioIntegration.h"
#import "SEGAnalyticsUtils.h"
#import <OCMock/OCMock.h>
#import <Expecta/Expecta.h>

//#import <Kiwi/Kiwi.h>

@interface SEGSegmentioIntegration (Private)
@property (nonatomic, readonly) NSMutableArray *queue;
@end

@interface SEGAnalytics (Private)
@property (nonatomic, strong) NSDictionary *cachedSettings;
@end


@interface SEGAnalyticsTests : XCTestCase

@property (nonatomic, strong) SEGAnalytics *analytics;
@property (nonatomic, strong) id mock;

@end

@implementation SEGAnalyticsTests

- (void)setUp {
  [super setUp];

  self.analytics = [[SEGAnalytics alloc] initWithConfiguration:[SEGAnalyticsConfiguration configurationWithWriteKey:@"k5l6rrye0hsv566zwuk7"]];
  self.analytics.cachedSettings = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:
                                                                                    [[NSBundle bundleForClass:[self class]]
                                                                                               URLForResource:@"settings" withExtension:@"json"]] options:NSJSONReadingMutableContainers error:NULL];
  self.mock = [OCMockObject partialMockForObject:[self.analytics.configuration.integrations objectForKey:@"Segment.io"]];
  [self.analytics.configuration.integrations setValue:self.mock forKey:@"Segment.io"];
}

- (void)testHasIntegrations {
  XCTAssertEqual(13, self.analytics.configuration.integrations.count);
}

- (void)testForwardsIdentify {
  [[self.mock expect] identify:[self identity] traits:[self traits] options:[self options]];

  [self.analytics identify:[self identity] traits:[self traits] options:[self options]];

  [self.mock verifyWithDelay:1];
}

- (void)testDoesntForwardIdentityWithoutUserIdOrTraits {
  [[self.mock reject] identify:nil traits:nil options:[self options]];
  [[self.mock reject] identify:nil traits:@{} options:[self options]];
  [[self.mock reject] identify:@"" traits:@{} options:[self options]];
  [[self.mock reject] identify:@"" traits:nil options:[self options]];

  EXP_expect(^{ [self.analytics identify:nil traits:nil options:[self options]]; });
  EXP_expect(^{ [self.analytics identify:nil traits:@{} options:[self options]]; });
  EXP_expect(^{ [self.analytics identify:@"" traits:@{} options:[self options]]; });
  EXP_expect(^{ [self.analytics identify:@"" traits:nil options:[self options]]; });

  [self.mock verifyWithDelay:1];
}

- (void)testForwardsTrack {
  [[self.mock expect] track:[self event] properties:[self properties] options:[self options]];

  [self.analytics track:[self event] properties:[self properties] options:[self options]];

  [self.mock verifyWithDelay:1];
}

- (void)testDoesntForwardTrackWithoutEvent {
  [[self.mock reject] track:@"" properties:[self properties] options:[self options]];
  [[self.mock reject] track:nil properties:[self properties] options:[self options]];

  EXP_expect(^{ [self.analytics track:@"" properties:[self properties] options:[self options]]; }).to.raiseAny();
  EXP_expect(^{ [self.analytics track:nil properties:[self properties] options:[self options]]; }).to.raiseAny();

  [self.mock verifyWithDelay:1];
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

@end
