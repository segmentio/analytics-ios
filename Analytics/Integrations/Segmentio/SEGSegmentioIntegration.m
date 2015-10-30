// SegmentioIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#include <sys/sysctl.h>

#import <UIKit/UIKit.h>
#if !(TARGET_OS_TV)
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#endif
#import "SEGAnalytics.h"
#import "SEGAnalyticsUtils.h"
#import "SEGAnalyticsRequest.h"
#import "SEGSegmentioIntegration.h"
#import "SEGBluetooth.h"
#import "SEGReachability.h"
#import "SEGLocation.h"
#if !(TARGET_OS_TV)
#import <iAd/iAd.h>
#endif

NSString *const SEGSegmentioDidSendRequestNotification = @"SegmentioDidSendRequest";
NSString *const SEGSegmentioRequestDidSucceedNotification = @"SegmentioRequestDidSucceed";
NSString *const SEGSegmentioRequestDidFailNotification = @"SegmentioRequestDidFail";

NSString *const SEGAdvertisingClassIdentifier = @"ASIdentifierManager";
NSString *const SEGADClientClass = @"ADClient";

static NSString *GenerateUUIDString()
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    NSString *UUIDString = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return UUIDString;
}

static NSString *GetAnonymousId(BOOL reset)
{
    // We've chosen to generate a UUID rather than use the UDID (deprecated in iOS 5),
    // identifierForVendor (iOS6 and later, can't be changed on logout),
    // or MAC address (blocked in iOS 7). For more info see https://segment.io/libraries/ios#ids
    NSURL *url = SEGAnalyticsURLForFilename(@"segmentio.anonymousId");
    NSString *anonymousId = [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
    if (!anonymousId || reset) {
        anonymousId = GenerateUUIDString();
        SEGLog(@"New anonymousId: %@", anonymousId);
        [anonymousId writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }
    return anonymousId;
}

static NSString *GetDeviceModel()
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char result[size];
    sysctlbyname("hw.machine", result, &size, NULL, 0);
    NSString *results = [NSString stringWithCString:result encoding:NSUTF8StringEncoding];
    return results;
}

static BOOL GetAdTrackingEnabled()
{
    BOOL result = NO;
    Class advertisingManager = NSClassFromString(SEGAdvertisingClassIdentifier);
    SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
    id sharedManager = ((id (*)(id, SEL))[advertisingManager methodForSelector:sharedManagerSelector])(advertisingManager, sharedManagerSelector);
    SEL adTrackingEnabledSEL = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
    result = ((BOOL (*)(id, SEL))[sharedManager methodForSelector:adTrackingEnabledSEL])(sharedManager, adTrackingEnabledSEL);
    return result;
}


@interface SEGSegmentioIntegration ()

@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic, strong) NSDictionary *context;
@property (nonatomic, strong) NSArray *batch;
@property (nonatomic, strong) SEGAnalyticsRequest *request;
@property (nonatomic, assign) UIBackgroundTaskIdentifier flushTaskID;
@property (nonatomic, strong) SEGBluetooth *bluetooth;
@property (nonatomic, strong) SEGReachability *reachability;
@property (nonatomic, strong) SEGLocation *location;
@property (nonatomic, strong) NSTimer *flushTimer;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSMutableDictionary *traits;
@property (nonatomic, assign) BOOL enableAdvertisingTracking;

@end


@implementation SEGSegmentioIntegration

- (id)initWithConfiguration:(SEGAnalyticsConfiguration *)configuration
{
    if (self = [super init]) {
        self.configuration = configuration;
        self.apiURL = [NSURL URLWithString:@"https://api.segment.io/v1/import"];
        self.anonymousId = GetAnonymousId(NO);
        self.userId = [[NSString alloc] initWithContentsOfURL:self.userIDURL encoding:NSUTF8StringEncoding error:NULL];
        self.bluetooth = [[SEGBluetooth alloc] init];
        self.reachability = [SEGReachability reachabilityWithHostname:@"http://google.com"];
        [self.reachability startNotifier];
        self.context = [self staticContext];
        self.flushTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(flush) userInfo:nil repeats:YES];
        self.serialQueue = seg_dispatch_queue_create_specific("io.segment.analytics.segmentio", DISPATCH_QUEUE_SERIAL);
        self.flushTaskID = UIBackgroundTaskInvalid;
        self.name = @"Segment.io";
        self.settings = @{ @"writeKey" : configuration.writeKey };
        [self validate];
        self.initialized = YES;
    }
    return self;
}

- (NSDictionary *)staticContext
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    dict[@"library"] = @{ @"name" : @"analytics-ios",
                          @"version" : SEGStringize(ANALYTICS_VERSION) };

    NSMutableDictionary *infoDictionary = [[[NSBundle mainBundle] infoDictionary] mutableCopy];
    [infoDictionary addEntriesFromDictionary:[[NSBundle mainBundle] localizedInfoDictionary]];
    if (infoDictionary.count) {
        dict[@"app"] = @{
            @"name" : infoDictionary[@"CFBundleDisplayName"] ?: @"",
            @"version" : infoDictionary[@"CFBundleShortVersionString"] ?: @"",
            @"build" : infoDictionary[@"CFBundleVersion"] ?: @"",
            @"namespace" : [[NSBundle mainBundle] bundleIdentifier] ?: @"",
        };
    }

    UIDevice *device = [UIDevice currentDevice];

    dict[@"device"] = ({
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        dict[@"manufacturer"] = @"Apple";
        dict[@"model"] = GetDeviceModel();
        dict[@"id"] = [[device identifierForVendor] UUIDString];
        if (NSClassFromString(SEGAdvertisingClassIdentifier)) {
            dict[@"adTrackingEnabled"] = @(GetAdTrackingEnabled());
        }
        if (self.enableAdvertisingTracking) {
            NSString *idfa = SEGIDFA();
            if (idfa.length) dict[@"advertisingId"] = idfa;
        }
        dict;
    });

    dict[@"os"] = @{
        @"name" : device.systemName,
        @"version" : device.systemVersion
    };

#if !(TARGET_OS_TV)
    CTCarrier *carrier = [[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider];
    if (carrier.carrierName.length)
        dict[@"network"] = @{ @"carrier" : carrier.carrierName };
#endif

    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    dict[@"screen"] = @{
        @"width" : @(screenSize.width),
        @"height" : @(screenSize.height)
    };

#if !(TARGET_IPHONE_SIMULATOR)
    Class adClient = NSClassFromString(SEGADClientClass);
    if (adClient) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id sharedClient = [adClient performSelector:NSSelectorFromString(@"sharedClient")];
#pragma clang diagnostic pop
        void (^completionHandler)(BOOL iad) = ^(BOOL iad) {
          if (iad) {
              dict[@"referrer"] = @{ @"type" : @"iad" };
          }
        };
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [sharedClient performSelector:NSSelectorFromString(@"determineAppInstallationAttributionWithCompletionHandler:")
                           withObject:completionHandler];
#pragma clang diagnostic pop
    }
#endif

    return dict;
}

- (NSDictionary *)liveContext
{
    NSMutableDictionary *context = [[NSMutableDictionary alloc] init];

    [context addEntriesFromDictionary:self.context];

    context[@"locale"] = [NSString stringWithFormat:
                                       @"%@-%@",
                                       [NSLocale.currentLocale objectForKey:NSLocaleLanguageCode],
                                       [NSLocale.currentLocale objectForKey:NSLocaleCountryCode]];

    context[@"timezone"] = [[NSTimeZone localTimeZone] name];

    context[@"network"] = ({
        NSMutableDictionary *network = [[NSMutableDictionary alloc] init];

        if (self.bluetooth.hasKnownState)
            network[@"bluetooth"] = @(self.bluetooth.isEnabled);

        if (self.reachability.isReachable) {
            network[@"wifi"] = @(self.reachability.isReachableViaWiFi);
            network[@"cellular"] = @(self.reachability.isReachableViaWWAN);
        }

        network;
    });

    if (self.location.hasKnownLocation)
        context[@"location"] = self.location.locationDictionary;

    context[@"traits"] = ({
        NSMutableDictionary *traits = [[NSMutableDictionary alloc] initWithDictionary:[self traits]];

        if (self.location.hasKnownLocation)
            traits[@"address"] = self.location.addressDictionary;

        traits;
    });

    return [context copy];
}

- (void)dispatchBackground:(void (^)(void))block
{
    seg_dispatch_specific_async(_serialQueue, block);
}

- (void)dispatchBackgroundAndWait:(void (^)(void))block
{
    seg_dispatch_specific_sync(_serialQueue, block);
}

- (void)beginBackgroundTask
{
    [self endBackgroundTask];

    self.flushTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
      [self endBackgroundTask];
    }];
}

- (void)endBackgroundTask
{
    [self dispatchBackgroundAndWait:^{
      if (self.flushTaskID != UIBackgroundTaskInvalid) {
          [[UIApplication sharedApplication] endBackgroundTask:self.flushTaskID];
          self.flushTaskID = UIBackgroundTaskInvalid;
      }
    }];
}

- (void)validate
{
    self.valid = ![[self.settings objectForKey:@"off"] boolValue];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%p:%@, %@>", self, self.class, [self.configuration dictionaryWithValuesForKeys:@[ @"writeKey" ]]];
}

- (void)saveUserId:(NSString *)userId
{
    [self dispatchBackground:^{
      self.userId = userId;
      [self.userId writeToURL:self.userIDURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }];
}

- (void)addTraits:(NSDictionary *)traits
{
    [self dispatchBackground:^{
      [self.traits addEntriesFromDictionary:traits];
      [[self.traits copy] writeToURL:self.traitsURL atomically:YES];
    }];
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    [self dispatchBackground:^{
      [self saveUserId:userId];
      [self addTraits:traits];
    }];

    [self enqueueAction:@"identify" dictionary:@{ @"traits" : traits } options:options];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    NSCParameterAssert(event.length > 0);

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:event forKey:@"event"];
    [dictionary setValue:properties forKey:@"properties"];

    [self enqueueAction:@"track" dictionary:dictionary options:options];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    NSCParameterAssert(screenTitle.length > 0);

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:screenTitle forKey:@"name"];
    [dictionary setValue:properties forKey:@"properties"];

    [self enqueueAction:@"screen" dictionary:dictionary options:options];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    NSCParameterAssert(groupId.length > 0);

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:groupId forKey:@"groupId"];
    [dictionary setValue:traits forKey:@"traits"];

    [self enqueueAction:@"group" dictionary:dictionary options:options];
}

- (void)alias:(NSString *)newId options:(NSDictionary *)options
{
    NSCParameterAssert(newId.length > 0);

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:newId forKey:@"userId"];
    [dictionary setValue:self.userId ?: self.anonymousId forKey:@"previousId"];

    [self enqueueAction:@"alias" dictionary:dictionary options:options];
}

- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken options:(NSDictionary *)options
{
    NSCParameterAssert(deviceToken != nil);

    const unsigned char *buffer = (const unsigned char *)[deviceToken bytes];
    if (!buffer) {
        return;
    }
    NSMutableString *token = [NSMutableString stringWithCapacity:(deviceToken.length * 2)];
    for (NSUInteger i = 0; i < deviceToken.length; i++) {
        [token appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)buffer[i]]];
    }
    [self.context[@"device"] setObject:[token copy] forKey:@"token"];
}

#pragma mark - Queueing

- (NSDictionary *)integrationsDictionary:(NSDictionary *)integrations
{
    NSMutableDictionary *dict = [integrations ?: @{} mutableCopy];
    for (SEGAnalyticsIntegration *integration in self.configuration.integrations.allValues) {
        if (![integration isKindOfClass:[SEGSegmentioIntegration class]]) {
            dict[integration.name] = @NO;
        }
    }
    return dict;
}

- (void)enqueueAction:(NSString *)action dictionary:(NSDictionary *)dictionary options:(NSDictionary *)options
{
    // attach these parts of the payload outside since they are all synchronous
    // and the timestamp will be more accurate.
    NSMutableDictionary *payload = [dictionary mutableCopy];
    payload[@"type"] = action;
    payload[@"timestamp"] = iso8601FormattedString([NSDate date]);
    payload[@"messageId"] = GenerateUUIDString();

    [self dispatchBackground:^{
      // attach userId and anonymousId inside the dispatch_async in case
      // they've changed (see identify function)
      [payload setValue:self.userId forKey:@"userId"];
      [payload setValue:self.anonymousId forKey:@"anonymousId"];

      [payload setValue:[self integrationsDictionary:options[@"integrations"]] forKey:@"integrations"];

      NSDictionary *defaultContext = [self liveContext];
      NSDictionary *customContext = options[@"context"];

      NSUInteger capacity = customContext.count + defaultContext.count;
      NSMutableDictionary *context = [NSMutableDictionary dictionaryWithCapacity:capacity];

      [context addEntriesFromDictionary:defaultContext];
      [context addEntriesFromDictionary:customContext]; // let the custom context override ours
      [payload setValue:context forKey:@"context"];

      SEGLog(@"%@ Enqueueing action: %@", self, payload);
      [self queuePayload:[payload copy]];
    }];
}

- (void)queuePayload:(NSDictionary *)payload
{
    @try {
        [self.queue addObject:payload];
        [[self.queue copy] writeToURL:[self queueURL] atomically:YES];
        [self flushQueueByLength];

    }
    @catch (NSException *exception) {
        SEGLog(@"%@ Error writing payload: %@", self, exception);
    }
}

- (void)flush
{
    [self flushWithMaxSize:self.maxBatchSize];
}

- (void)flushWithMaxSize:(NSUInteger)maxBatchSize
{
    [self dispatchBackground:^{
      if ([self.queue count] == 0) {
          SEGLog(@"%@ No queued API calls to flush.", self);
          return;
      } else if (self.request != nil) {
          SEGLog(@"%@ API request already in progress, not flushing again.", self);
          return;
      } else if ([self.queue count] >= maxBatchSize) {
          self.batch = [self.queue subarrayWithRange:NSMakeRange(0, maxBatchSize)];
      } else {
          self.batch = [NSArray arrayWithArray:self.queue];
      }

      SEGLog(@"%@ Flushing %lu of %lu queued API calls.", self, (unsigned long)self.batch.count, (unsigned long)self.queue.count);

      NSMutableDictionary *payloadDictionary = [[NSMutableDictionary alloc] init];
      [payloadDictionary setObject:self.configuration.writeKey forKey:@"writeKey"];
      [payloadDictionary setObject:iso8601FormattedString([NSDate date]) forKey:@"sentAt"];
      [payloadDictionary setObject:self.context forKey:@"context"];
      [payloadDictionary setObject:self.batch forKey:@"batch"];

      SEGLog(@"Flushing payload %@", payloadDictionary);

      NSError *error = nil;
      NSException *exception = nil;
      NSData *payload = nil;
      @try {
          payload = [NSJSONSerialization dataWithJSONObject:payloadDictionary options:0 error:&error];
      }
      @catch (NSException *exc) {
          exception = exc;
      }
      if (error || exception) {
          SEGLog(@"%@ Error serializing JSON: %@", self, error);
      } else {
          [self sendData:payload];
      }
    }];
}

- (void)flushQueueByLength
{
    [self dispatchBackground:^{
      SEGLog(@"%@ Length is %lu.", self, (unsigned long)self.queue.count);

      if (self.request == nil && [self.queue count] >= self.configuration.flushAt) {
          [self flush];
      }
    }];
}

- (void)reset
{
    [self dispatchBackgroundAndWait:^{
      [[NSFileManager defaultManager] removeItemAtURL:self.userIDURL error:NULL];
      [[NSFileManager defaultManager] removeItemAtURL:self.traitsURL error:NULL];
      [[NSFileManager defaultManager] removeItemAtURL:self.queueURL error:NULL];
      self.userId = nil;
      self.queue = [NSMutableArray array];
      self.anonymousId = GetAnonymousId(YES);
      self.request.completion = nil;
      self.request = nil;
    }];
}

- (void)notifyForName:(NSString *)name userInfo:(id)userInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:name object:self];
      SEGLog(@"sent notification %@", name);
    });
}

- (void)sendData:(NSData *)data
{
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:self.apiURL];
    [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:data];

    SEGLog(@"%@ Sending batch API request.", self);
    self.request = [SEGAnalyticsRequest startWithURLRequest:urlRequest
                                                 completion:^{
                                                   [self dispatchBackground:^{
                                                     if (self.request.error) {
                                                         SEGLog(@"%@ API request had an error: %@", self, self.request.error);
                                                         [self notifyForName:SEGSegmentioRequestDidFailNotification userInfo:self.batch];
                                                     } else {
                                                         SEGLog(@"%@ API request success 200", self);
                                                         [self.queue removeObjectsInArray:self.batch];
                                                         [[self.queue copy] writeToURL:[self queueURL] atomically:YES];
                                                         [self notifyForName:SEGSegmentioRequestDidSucceedNotification userInfo:self.batch];
                                                     }

                                                     self.batch = nil;
                                                     self.request = nil;
                                                     [self endBackgroundTask];
                                                   }];
                                                 }];
    [self notifyForName:SEGSegmentioDidSendRequestNotification userInfo:self.batch];
}

- (void)applicationDidEnterBackground
{
    [self beginBackgroundTask];
    // We are gonna try to flush as much as we reasonably can when we enter background
    // since there is a chance that the user will never launch the app again.
    [self flush];
}

- (void)applicationWillTerminate
{
    [self dispatchBackgroundAndWait:^{
      if (self.queue.count)
          [[self.queue copy] writeToURL:self.queueURL atomically:YES];
    }];
}

#pragma mark - Initialization

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:@"Segment.io"];
}

#pragma mark - Private

- (NSMutableArray *)queue
{
    if (!_queue) {
        _queue = [NSMutableArray arrayWithContentsOfURL:self.queueURL] ?: [[NSMutableArray alloc] init];
    }
    return _queue;
}

- (NSMutableDictionary *)traits
{
    if (!_traits) {
        _traits = [NSMutableDictionary dictionaryWithContentsOfURL:self.traitsURL] ?: [[NSMutableDictionary alloc] init];
    }
    return _traits;
}

- (NSUInteger)maxBatchSize
{
    return 100;
}

- (NSURL *)userIDURL
{
    return SEGAnalyticsURLForFilename(@"segmentio.userId");
}

- (NSURL *)queueURL
{
    return SEGAnalyticsURLForFilename(@"segmentio.queue.plist");
}

- (NSURL *)traitsURL
{
    return SEGAnalyticsURLForFilename(@"segmentio.traits.plist");
}

- (void)setConfiguration:(SEGAnalyticsConfiguration *)configuration
{
    if (self.configuration) {
        [self.configuration removeObserver:self forKeyPath:@"shouldUseLocationServices"];
        [self.configuration removeObserver:self forKeyPath:@"enableAdvertisingTracking"];
    }

    [super setConfiguration:configuration];
    [self.configuration addObserver:self forKeyPath:@"shouldUseLocationServices" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    [self.configuration addObserver:self forKeyPath:@"enableAdvertisingTracking" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
}

#pragma mark - Key value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"shouldUseLocationServices"]) {
        self.location = [object shouldUseLocationServices] ? [SEGLocation new] : nil;
    } else if ([keyPath isEqualToString:@"enableAdvertisingTracking"]) {
        self.enableAdvertisingTracking = [object enableAdvertisingTracking];
    } else if ([keyPath isEqualToString:@"flushAt"]) {
        [self flushQueueByLength];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
