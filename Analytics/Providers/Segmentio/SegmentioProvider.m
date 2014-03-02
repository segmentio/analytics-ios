// SegmentioProvider.m
// Copyright 2013 Segment.io

#include <sys/sysctl.h>

#import <UIKit/UIKit.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "Analytics.h"
#import "AnalyticsUtils.h"
#import "AnalyticsRequest.h"
#import "SegmentioProvider.h"

#define SEGMENTIO_API_URL [NSURL URLWithString:@"https://api.segment.io/v1/import"]
#define SEGMENTIO_MAX_BATCH_SIZE 100
#define DISK_SESSION_ID_URL AnalyticsURLForFilename(@"segmentio.sessionID")
#define DISK_USER_ID_URL AnalyticsURLForFilename(@"segmentio.userID")
#define DISK_QUEUE_URL AnalyticsURLForFilename(@"segmentio.queue.plist")
#define DISK_TRAITS_URL AnalyticsURLForFilename(@"segmentio.traits.plist")

NSString *const SegmentioDidSendRequestNotification = @"SegmentioDidSendRequest";
NSString *const SegmentioRequestDidSucceedNotification = @"SegmentioRequestDidSucceed";
NSString *const SegmentioRequestDidFailNotification = @"SegmentioRequestDidFail";

static NSString *GenerateUUIDString() {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    NSString *UUIDString = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return UUIDString;
}

static NSString *GetSessionID(BOOL reset) {
    // We've chosen to generate a UUID rather than use the UDID (deprecated in iOS 5),
    // identifierForVendor (iOS6 and later, can't be changed on logout),
    // or MAC address (blocked in iOS 7). For more info see https://segment.io/libraries/ios#ids
    NSURL *url = DISK_SESSION_ID_URL;
    NSString *sessionID = [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
    if (!sessionID || reset) {
        sessionID = GenerateUUIDString();
        SOLog(@"New SessionID: %@", sessionID);
        [sessionID writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }
    return sessionID;
}

@interface SegmentioProvider ()

@property (nonatomic, weak) Analytics *analytics;
@property (nonatomic, strong) NSTimer *flushTimer;
@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic, strong) NSArray *batch;
@property (nonatomic, strong) AnalyticsRequest *request;
@property (nonatomic, assign) UIBackgroundTaskIdentifier flushTaskID;

@end


@implementation SegmentioProvider {
    dispatch_queue_t _serialQueue;
    NSMutableDictionary *_traits;
    NSMutableDictionary *_context;
}

- (id)initWithAnalytics:(Analytics *)analytics {
    if (self = [self initWithWriteKey:analytics.writeKey flushAt:20 flushAfter:30]) {
        self.analytics = analytics;
    }
    return self;
}

- (id)initWithWriteKey:(NSString *)writeKey flushAt:(NSUInteger)flushAt flushAfter:(NSUInteger)flushAfter {
    NSParameterAssert(writeKey.length);
    NSParameterAssert(flushAt > 0);
    NSParameterAssert(flushAfter > 0);
    
    if (self = [self init]) {
        _flushAt = flushAt;
        _flushAfter = flushAfter;
        _writeKey = writeKey;
        _sessionId = GetSessionID(NO);
        _userId = [NSString stringWithContentsOfURL:DISK_USER_ID_URL encoding:NSUTF8StringEncoding error:NULL];
        _queue = [NSMutableArray arrayWithContentsOfURL:DISK_QUEUE_URL];
        if (!_queue)
            _queue = [[NSMutableArray alloc] init];
        _traits = [NSMutableDictionary dictionaryWithContentsOfURL:DISK_TRAITS_URL];
        if (!_traits)
            _traits = [[NSMutableDictionary alloc] init];
        _context = [self buildContextDictionary];
        _flushTimer = [NSTimer scheduledTimerWithTimeInterval:self.flushAfter
                                                       target:self
                                                     selector:@selector(flush)
                                                     userInfo:nil
                                                      repeats:YES];
        _serialQueue = dispatch_queue_create_specific("io.segment.analytics.segmentio", DISPATCH_QUEUE_SERIAL);
        _flushTaskID = UIBackgroundTaskInvalid;
        
        self.name = @"Segment.io";
        self.valid = NO;
        self.initialized = NO;
        self.settings = [NSDictionary dictionaryWithObjectsAndKeys:writeKey, @"writeKey", nil];
        [self validate];
        self.initialized = YES;

    }
    return self;
}

- (NSMutableDictionary *)buildContextDictionary
{
    NSMutableDictionary *context = [NSMutableDictionary dictionary];
    
    // Library
    context[@"library"] = @{
        @"name" : @"analytics-ios",
        @"version" : NSStringize(ANALYTICS_VERSION)
    };
    
    // App
    context[@"app"] = @{
        @"name":    [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"],
        @"version": [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
        @"build":   [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]
    };
    
    // Device
    UIDevice *device = [UIDevice currentDevice];
    NSString *deviceModel = [self deviceModel];
    context[@"device"] = @{
        @"manufacturer": @"Apple",
        @"model": deviceModel,
        @"idfv": [[device identifierForVendor] UUIDString],
        @"idfa": [self getIdForAdvertiser]
    };
    
    // OS
    context[@"os"] = @{
        @"name": [device systemName],
        @"version": [device systemVersion]
    };
    
    // Telephony
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    if (carrier.carrierName.length) {
        context[@"telephony"] = @{
            @"carrier": carrier.carrierName
        };
    }
    
    // Screen
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    context[@"os"] = @{
        @"width":  [NSNumber numberWithInt:(int)screenSize.width],
        @"height": [NSNumber numberWithInt:(int)screenSize.height]
    };
    
    return context;
}

- (NSMutableDictionary *)updatedContext {
    // Network
    // TODO https://github.com/segmentio/spec/issues/30
    
    // Traits
    // TODO https://github.com/segmentio/spec/issues/29
    
    return _context;
}

- (NSString *)getIdForAdvertiser
{
    if (NSClassFromString(@"ASIdentifierManager")) {
        NSString* idForAdvertiser = nil;
        Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
        if (ASIdentifierManagerClass) {
            SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
            id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
            SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
            NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
            idForAdvertiser = [uuid UUIDString];
        }
        return idForAdvertiser;
    }
    else {
        return nil;
    }
}

- (NSString *)deviceModel
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char result[size];
    sysctlbyname("hw.machine", result, &size, NULL, 0);
    NSString *results = [NSString stringWithCString:result encoding:NSUTF8StringEncoding];
    return results;
}

- (void)dispatchBackground:(void(^)(void))block {
    dispatch_specific_async(_serialQueue, block);
}

- (void)dispatchBackgroundAndWait:(void(^)(void))block {
    dispatch_specific_sync(_serialQueue, block);
}

- (void)beginBackgroundTask {
    [self endBackgroundTask];
    self.flushTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask];
    }];
}

- (void)endBackgroundTask {
    [self dispatchBackgroundAndWait:^{
        if (self.flushTaskID != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.flushTaskID];
            self.flushTaskID = UIBackgroundTaskInvalid;
        }
    }];
}

- (void)updateSettings:(NSDictionary *)settings {
    
}

- (void)validate {
    BOOL hasWriteKey = [self.settings objectForKey:@"writeKey"] != nil;
    self.valid = hasWriteKey;
}

- (NSString *)getSessionId {
    return self.sessionId;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<SegmentioProvider writeKey:%@>", self.writeKey];
}

- (void)saveUserId:(NSString *)userId {
    [self dispatchBackground:^{
        self.userId = userId;
        [_userId writeToURL:DISK_USER_ID_URL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }];
}

- (void)addTraits:(NSDictionary *)traits {
    [self dispatchBackground:^{
        [_traits addEntriesFromDictionary:traits];
        [_traits writeToURL:DISK_TRAITS_URL atomically:YES];
    }];
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {
    [self dispatchBackground:^{
        [self saveUserId:userId];
        [self addTraits:traits];
    }];

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:traits forKey:@"traits"];

    [self enqueueAction:@"identify" dictionary:dictionary options:options];
}

 - (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
    NSAssert(event.length, @"%@ track requires an event name.", self);

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:event forKey:@"event"];
    [dictionary setValue:properties forKey:@"properties"];
    
    [self enqueueAction:@"track" dictionary:dictionary options:options];
 }

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options {
    NSAssert(screenTitle.length, @"%@ screen requires a screen title.", self);
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:screenTitle forKey:@"name"];
    [dictionary setValue:properties forKey:@"properties"];
    
    [self enqueueAction:@"screen" dictionary:dictionary options:options];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options {
    NSAssert(groupId.length, @"%@ group requires a groupId.", self);
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:groupId forKey:@"groupId"];
    [dictionary setValue:traits forKey:@"traits"];
    
    [self enqueueAction:@"group" dictionary:dictionary options:options];
}

#pragma mark - Queueing

- (NSDictionary *)integrationsDictionary:(NSDictionary *)options {
    NSMutableDictionary *integrations = [options ?: @{} mutableCopy];
    for (AnalyticsProvider *provider in self.analytics.providers.allValues) {
        if (![provider isKindOfClass:[SegmentioProvider class]]) {
            integrations[provider.name] = @NO;
        }
    }
    return integrations;
}

- (void)enqueueAction:(NSString *)action dictionary:(NSMutableDictionary *)dictionary options:(NSDictionary *)options {
    // attach these parts of the payload outside since they are all synchronous
    // and the timestamp will be more accurate.
    NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    payload[@"action"] = action;
    payload[@"timestamp"] = [[NSDate date] description];
    payload[@"requestId"] = GenerateUUIDString();

    [self dispatchBackground:^{
        // attach userId and sessionId inside the dispatch_async in case
        // they've changed (see identify function)
        [payload setValue:self.userId forKey:@"userId"];
        [payload setValue:self.sessionId forKey:@"anonymousId"];
        SOLog(@"%@ Enqueueing action: %@", self, payload);
        
        [payload setValue:[self integrationsDictionary:options] forKey:@"integrations"];
        [payload setValue:[self updatedContext] forKey:@"context"];
        [self.queue addObject:payload];
        [self flushQueueByLength];
    }];
}

- (void)flush {
    [self flushWithMaxSize:SEGMENTIO_MAX_BATCH_SIZE];
}

- (void)flushWithMaxSize:(NSUInteger)maxBatchSize {
    [self dispatchBackground:^{
        if ([self.queue count] == 0) {
            SOLog(@"%@ No queued API calls to flush.", self);
            return;
        } else if (self.request != nil) {
            SOLog(@"%@ API request already in progress, not flushing again.", self);
            NSLog(@"%@ %@", self.batch, self.request);
            return;
        } else if ([self.queue count] >= maxBatchSize) {
            self.batch = [self.queue subarrayWithRange:NSMakeRange(0, maxBatchSize)];
        } else {
            self.batch = [NSArray arrayWithArray:self.queue];
        }
        
        SOLog(@"%@ Flushing %lu of %lu queued API calls.", self, (unsigned long)self.batch.count, (unsigned long)self.queue.count);
        
        NSMutableDictionary *payloadDictionary = [NSMutableDictionary dictionary];
        [payloadDictionary setObject:self.writeKey forKey:@"writeKey"];
        [payloadDictionary setObject:[[NSDate date] description] forKey:@"sentAt"];
        [payloadDictionary setObject:self.batch forKey:@"batch"];
        
        NSData *payload = [NSJSONSerialization dataWithJSONObject:payloadDictionary
                                                          options:0 error:NULL];
        [self sendData:payload];
    }];
}

- (void)flushQueueByLength {
    [self dispatchBackground:^{
        SOLog(@"%@ Length is %lu.", self, (unsigned long)self.queue.count);
        if (self.request == nil && [self.queue count] >= self.flushAt) {
            [self flush];
        }
    }];
}

- (void)reset {
    [self.flushTimer invalidate];
    self.flushTimer = nil;
    self.flushTimer = [NSTimer scheduledTimerWithTimeInterval:self.flushAfter
                                                       target:self
                                                     selector:@selector(flush)
                                                     userInfo:nil
                                                      repeats:YES];
    [self dispatchBackgroundAndWait:^{
        [[NSFileManager defaultManager] removeItemAtURL:DISK_SESSION_ID_URL error:NULL];
        [[NSFileManager defaultManager] removeItemAtURL:DISK_USER_ID_URL error:NULL];
        [[NSFileManager defaultManager] removeItemAtURL:DISK_TRAITS_URL error:NULL];
        [[NSFileManager defaultManager] removeItemAtURL:DISK_QUEUE_URL error:NULL];
        self.userId = nil;
        self.queue = [NSMutableArray array];
        self.request.completion = nil;
        self.request = nil;
    }];
}

- (void)notifyForName:(NSString *)name userInfo:(id)userInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:self];
        NSLog(@"sent notification %@", name);
    });
}

- (void)sendData:(NSData *)data {
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:SEGMENTIO_API_URL];
    [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:data];
    SOLog(@"%@ Sending batch API request.", self);
    self.request = [AnalyticsRequest startWithURLRequest:urlRequest completion:^{
        [self dispatchBackground:^{
            if (self.request.error) {
                SOLog(@"%@ API request had an error: %@", self, self.request.error);
                [self notifyForName:SegmentioRequestDidFailNotification userInfo:self.batch];
            } else {
                SOLog(@"%@ API request success 200", self);
                [self.queue removeObjectsInArray:self.batch];
                [self notifyForName:SegmentioRequestDidSucceedNotification userInfo:self.batch];
            }
            
            self.batch = nil;
            self.request = nil;
            [self endBackgroundTask];
        }];
    }];
    [self notifyForName:SegmentioDidSendRequestNotification userInfo:self.batch];
}

- (void)applicationDidEnterBackground {
    [self beginBackgroundTask];
    // We are gonna try to flush as much as we reasonably can when we enter background
    // since there is a chance that the user will never launch the app again.
    [self flushWithMaxSize:1000];
}

- (void)applicationWillTerminate {
    [self dispatchBackgroundAndWait:^{
        if (self.queue.count)
            [self.queue writeToURL:DISK_QUEUE_URL atomically:YES];
    }];
}

#pragma mark - Class Methods

+ (void)load {
    [Analytics registerProvider:self withIdentifier:@"Segment.io"];
}

@end
