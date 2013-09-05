// SegmentioProvider.m
// Copyright 2013 Segment.io

#import <UIKit/UIKit.h>
#import "Analytics.h"
#import "AnalyticsUtils.h"
#import "AnalyticsRequest.h"
#import "SegmentioProvider.h"

#define SEGMENTIO_API_URL [NSURL URLWithString:@"https://api.segment.io/v1/import"]
#define SEGMENTIO_MAX_BATCH_SIZE 100
#define DISK_SESSION_ID_URL AnalyticsURLForFilename(@"segmentio.sessionID")
#define DISK_QUEUE_URL AnalyticsURLForFilename(@"segmentio.queue.plist")
#define DISK_TRAITS_URL AnalyticsURLForFilename(@"segmentio.traits.plist")

NSString *const SegmentioDidSendRequestNotification = @"SegmentioDidSendRequest";
NSString *const SegmentioRequestDidSucceedNotification = @"SegmentioRequestDidSucceed";
NSString *const SegmentioRequestDidFailNotification = @"SegmentioRequestDidFail";

static NSString *GetSessionID(BOOL reset) {
    // We've chosen to generate a UUID rather than use the UDID (deprecated in iOS 5),
    // identifierForVendor (iOS6 and later, can't be changed on logout),
    // or MAC address (blocked in iOS 7). For more info see https://segment.io/libraries/ios#ids
    NSURL *url = DISK_SESSION_ID_URL;
    NSString *sessionID = [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
    if (!sessionID || reset) {
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        sessionID = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
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
}

- (id)initWithAnalytics:(Analytics *)analytics {
    if (self = [self initWithSecret:analytics.secret flushAt:20 flushAfter:30]) {
        self.analytics = analytics;
    }
    return self;
}

- (id)initWithSecret:(NSString *)secret flushAt:(NSUInteger)flushAt flushAfter:(NSUInteger)flushAfter {
    NSParameterAssert(secret.length);
    NSParameterAssert(flushAt > 0);
    NSParameterAssert(flushAfter > 0);
    
    if (self = [self init]) {
        _flushAt = flushAt;
        _flushAfter = flushAfter;
        _secret = secret;
        _sessionId = GetSessionID(NO);
        _queue = [NSMutableArray arrayWithContentsOfURL:DISK_QUEUE_URL];
        if (!_queue)
            _queue = [[NSMutableArray alloc] init];
        _traits = [NSMutableDictionary dictionaryWithContentsOfURL:DISK_TRAITS_URL];
        if (!_traits)
            _traits = [[NSMutableDictionary alloc] init];
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
        self.settings = [NSDictionary dictionaryWithObjectsAndKeys:secret, @"secret", nil];
        [self validate];
        self.initialized = YES;

    }
    return self;
}

- (void)dispatchBackground:(void(^)(void))block {
    dispatch_specific_async(_serialQueue, block);
}

- (void)dispatchBackgroundAndWait:(void(^)(void))block {
    dispatch_specific_sync(_serialQueue, block);
}

- (void)beginBackgroundTask {
    NSParameterAssert(self.flushTaskID == UIBackgroundTaskInvalid);
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
    BOOL hasSecret = [self.settings objectForKey:@"secret"] != nil;
    self.valid = hasSecret;
}

- (NSString *)getSessionId {
    return self.sessionId;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<SegmentioProvider secret:%@>", self.secret];
}

- (void)addTraits:(NSDictionary *)traits {
    [self dispatchBackground:^{
        [_traits addEntriesFromDictionary:traits];
        [_traits writeToURL:DISK_TRAITS_URL atomically:YES];
    }];
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context {
    [self dispatchBackground:^{
        self.userId = userId;
    }];

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:traits forKey:@"traits"];

    [self enqueueAction:@"identify" dictionary:dictionary context:context];
}

 - (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context {
    NSAssert(event.length, @"%@ track requires an event name.", self);

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:event forKey:@"event"];
    [dictionary setValue:properties forKey:@"properties"];
    
    [self enqueueAction:@"track" dictionary:dictionary context:context];
}

- (void)alias:(NSString *)from to:(NSString *)to context:(NSDictionary *)context {
    NSAssert(from.length, @"%@ alias requires a from id.", self);
    NSAssert(to.length, @"%@ alias requires a to id.", self);

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:from forKey:@"from"];
    [dictionary setValue:to forKey:@"to"];
    
    [self enqueueAction:@"alias" dictionary:dictionary context:context];
}

#pragma mark - Queueing

- (NSDictionary *)serverContextForContext:(NSDictionary *)context {
    NSMutableDictionary *serverContext = [context ?: @{} mutableCopy];
    NSMutableDictionary *providersDict = [context[@"providers"] ?: @{} mutableCopy];
    for (AnalyticsProvider *provider in self.analytics.providers.allValues)
        if (![provider isKindOfClass:[SegmentioProvider class]])
            providersDict[provider.name] = @NO;
    serverContext[@"providers"] = providersDict;
    serverContext[@"library"] = @"analytics-ios";
    serverContext[@"library-version"] = NSStringize(ANALYTICS_VERSION);
    serverContext[@"traits"] = _traits;
    return serverContext;
    
}

- (void)enqueueAction:(NSString *)action dictionary:(NSMutableDictionary *)dictionary context:(NSDictionary *)context {
    // attach these parts of the payload outside since they are all synchronous
    // and the timestamp will be more accurate.
    NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    payload[@"action"] = action;
    payload[@"timestamp"] = [[NSDate date] description];

    [self dispatchBackground:^{
        // attach userId and sessionId inside the dispatch_async in case
        // they've changed (see identify function)
        [payload setValue:self.userId forKey:@"userId"];
        [payload setValue:self.sessionId forKey:@"sessionId"];
        [payload setValue:[self serverContextForContext:context] forKey:@"context"];
        
        SOLog(@"%@ Enqueueing action: %@", self, payload);
        
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
        [payloadDictionary setObject:self.secret forKey:@"secret"];
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
    SOLog(@"%@ Sending batch API request: %@", self,
          [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    self.request = [AnalyticsRequest startWithURLRequest:urlRequest completion:^{
        [self dispatchBackground:^{
            if (self.request.error) {
                SOLog(@"%@ API request had an error: %@", self, self.request.error);
                [self notifyForName:SegmentioRequestDidFailNotification userInfo:self.batch];
            } else {
                SOLog(@"%@ API request success 200", self);
                // TODO
                // Currently we don't actively retry sending any of batched calls
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
