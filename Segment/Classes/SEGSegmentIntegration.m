#include <sys/sysctl.h>

#import "SEGAnalytics.h"
#import "SEGUtils.h"
#import "SEGSegmentIntegration.h"
#import "SEGReachability.h"
#import "SEGHTTPClient.h"
#import "SEGStorage.h"
#import "SEGMacros.h"
#import "SEGState.h"

#if TARGET_OS_IPHONE
@import UIKit;
#endif

NSString *const kSEGSegmentDestinationName = @"Segment.io";

NSString *const SEGSegmentDidSendRequestNotification = @"SegmentDidSendRequest";
NSString *const SEGSegmentRequestDidSucceedNotification = @"SegmentRequestDidSucceed";
NSString *const SEGSegmentRequestDidFailNotification = @"SegmentRequestDidFail";

NSString *const SEGUserIdKey = @"SEGUserId";
NSString *const SEGQueueKey = @"SEGQueue";
NSString *const SEGTraitsKey = @"SEGTraits";

NSString *const kSEGUserIdFilename = @"segmentio.userId";
NSString *const kSEGQueueFilename = @"segmentio.queue.plist";
NSString *const kSEGTraitsFilename = @"segmentio.traits.plist";

// Equiv to UIBackgroundTaskInvalid.
NSUInteger const kSEGBackgroundTaskInvalid = 0;

@interface SEGSegmentIntegration ()

@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic, strong) NSURLSessionUploadTask *batchRequest;
@property (nonatomic, strong) SEGReachability *reachability;
@property (nonatomic, strong) NSTimer *flushTimer;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) dispatch_queue_t backgroundTaskQueue;
@property (nonatomic, strong) NSDictionary *traits;
@property (nonatomic, assign) SEGAnalytics *analytics;
@property (nonatomic, assign) SEGAnalyticsConfiguration *configuration;
@property (atomic, copy) NSDictionary *referrer;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, strong) SEGHTTPClient *httpClient;
@property (nonatomic, strong) id<SEGStorage> fileStorage;
@property (nonatomic, strong) id<SEGStorage> userDefaultsStorage;

#if TARGET_OS_IPHONE
@property (nonatomic, assign) UIBackgroundTaskIdentifier flushTaskID;
#else
@property (nonatomic, assign) NSUInteger flushTaskID;
#endif

@end

@interface SEGAnalytics ()
@property (nonatomic, strong, readonly) SEGAnalyticsConfiguration *oneTimeConfiguration;
@end

@implementation SEGSegmentIntegration

- (id)initWithAnalytics:(SEGAnalytics *)analytics httpClient:(SEGHTTPClient *)httpClient fileStorage:(id<SEGStorage>)fileStorage userDefaultsStorage:(id<SEGStorage>)userDefaultsStorage;
{
    if (self = [super init]) {
        self.analytics = analytics;
        self.configuration = analytics.oneTimeConfiguration;
        self.httpClient = httpClient;
        self.httpClient.httpSessionDelegate = analytics.oneTimeConfiguration.httpSessionDelegate;
        self.fileStorage = fileStorage;
        self.userDefaultsStorage = userDefaultsStorage;
        self.reachability = [SEGReachability reachabilityWithHostname:@"google.com"];
        [self.reachability startNotifier];
        self.serialQueue = seg_dispatch_queue_create_specific("io.segment.analytics.segmentio", DISPATCH_QUEUE_SERIAL);
        self.backgroundTaskQueue = seg_dispatch_queue_create_specific("io.segment.analytics.backgroundTask", DISPATCH_QUEUE_SERIAL);
#if TARGET_OS_IPHONE
        self.flushTaskID = UIBackgroundTaskInvalid;
#else
        self.flushTaskID = 0; // the actual value of UIBackgroundTaskInvalid
#endif
        
        // load traits & user from disk.
        [self loadUserId];
        [self loadTraits];

        [self dispatchBackground:^{
            // Check for previous queue data in NSUserDefaults and remove if present.
            if ([[NSUserDefaults standardUserDefaults] objectForKey:SEGQueueKey]) {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:SEGQueueKey];
            }
#if !TARGET_OS_TV
            // Check for previous track data in NSUserDefaults and remove if present (Traits still exist in NSUserDefaults on tvOS)
            if ([[NSUserDefaults standardUserDefaults] objectForKey:SEGTraitsKey]) {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:SEGTraitsKey];
            }
#endif
        }];

        self.flushTimer = [NSTimer timerWithTimeInterval:self.configuration.flushInterval
                                                  target:self
                                                selector:@selector(flush)
                                                userInfo:nil
                                                 repeats:YES];
        
        [NSRunLoop.mainRunLoop addTimer:self.flushTimer
                                forMode:NSDefaultRunLoopMode];        
    }
    return self;
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

    seg_dispatch_specific_sync(_backgroundTaskQueue, ^{
        
        id<SEGApplicationProtocol> application = [self.analytics oneTimeConfiguration].application;
        if (application && [application respondsToSelector:@selector(seg_beginBackgroundTaskWithName:expirationHandler:)]) {
            self.flushTaskID = [application seg_beginBackgroundTaskWithName:@"Segmentio.Flush"
                                                          expirationHandler:^{
                                                              [self endBackgroundTask];
                                                          }];
        }
    });
}

- (void)endBackgroundTask
{
    // endBackgroundTask and beginBackgroundTask can be called from main thread
    // We should not dispatch to the same queue we use to flush events because it can cause deadlock
    // inside @synchronized(self) block for SEGIntegrationsManager as both events queue and main queue
    // attempt to call forwardSelector:arguments:options:
    // See https://github.com/segmentio/analytics-ios/issues/683
    seg_dispatch_specific_sync(_backgroundTaskQueue, ^{
        if (self.flushTaskID != kSEGBackgroundTaskInvalid) {
            id<SEGApplicationProtocol> application = [self.analytics oneTimeConfiguration].application;
            if (application && [application respondsToSelector:@selector(seg_endBackgroundTask:)]) {
                [application seg_endBackgroundTask:self.flushTaskID];
            }

            self.flushTaskID = kSEGBackgroundTaskInvalid;
        }
    });
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%p:%@, %@>", self, self.class, self.configuration.writeKey];
}

- (NSString *)userId
{
    return [SEGState sharedInstance].userInfo.userId;
}

- (void)setUserId:(NSString *)userId
{
    [self dispatchBackground:^{
        [SEGState sharedInstance].userInfo.userId = userId;
#if TARGET_OS_TV
        [self.userDefaultsStorage setString:userId forKey:SEGUserIdKey];
#else
        [self.fileStorage setString:userId forKey:kSEGUserIdFilename];
#endif
    }];
}

- (NSDictionary *)traits
{
    return [SEGState sharedInstance].userInfo.traits;
}

- (void)setTraits:(NSDictionary *)traits
{
    [self dispatchBackground:^{
        [SEGState sharedInstance].userInfo.traits = traits;
#if TARGET_OS_TV
        [self.userDefaultsStorage setDictionary:[self.traits copy] forKey:SEGTraitsKey];
#else
        [self.fileStorage setDictionary:[self.traits copy] forKey:kSEGTraitsFilename];
#endif
    }];
}

#pragma mark - Analytics API

- (void)identify:(SEGIdentifyPayload *)payload
{
    [self dispatchBackground:^{
        self.userId = payload.userId;
        self.traits = payload.traits;
    }];

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.traits forKey:@"traits"];
    [dictionary setValue:payload.timestamp forKey:@"timestamp"];
    [dictionary setValue:payload.messageId forKey:@"messageId"];
    [self enqueueAction:@"identify" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

- (void)track:(SEGTrackPayload *)payload
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.event forKey:@"event"];
    [dictionary setValue:payload.properties forKey:@"properties"];
    [dictionary setValue:payload.timestamp forKey:@"timestamp"];
    [dictionary setValue:payload.messageId forKey:@"messageId"];
    [self enqueueAction:@"track" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

- (void)screen:(SEGScreenPayload *)payload
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.name forKey:@"name"];
    [dictionary setValue:payload.properties forKey:@"properties"];
    [dictionary setValue:payload.timestamp forKey:@"timestamp"];
    [dictionary setValue:payload.messageId forKey:@"messageId"];

    [self enqueueAction:@"screen" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

- (void)group:(SEGGroupPayload *)payload
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.groupId forKey:@"groupId"];
    [dictionary setValue:payload.traits forKey:@"traits"];
    [dictionary setValue:payload.timestamp forKey:@"timestamp"];
    [dictionary setValue:payload.messageId forKey:@"messageId"];

    [self enqueueAction:@"group" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

- (void)alias:(SEGAliasPayload *)payload
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:payload.theNewId forKey:@"userId"];
    [dictionary setValue:self.userId ?: [self.analytics getAnonymousId] forKey:@"previousId"];
    [dictionary setValue:payload.timestamp forKey:@"timestamp"];
    [dictionary setValue:payload.messageId forKey:@"messageId"];

    [self enqueueAction:@"alias" dictionary:dictionary context:payload.context integrations:payload.integrations];
}

#pragma mark - Queueing

// Merges user provided integration options with bundled integrations.
- (NSDictionary *)integrationsDictionary:(NSDictionary *)integrations
{
    NSMutableDictionary *dict = [integrations ?: @{} mutableCopy];
    for (NSString *integration in self.analytics.bundledIntegrations) {
        // Don't record Segment.io in the dictionary. It is always enabled.
        if ([integration isEqualToString:kSEGSegmentDestinationName]) {
            continue;
        }
        dict[integration] = @NO;
    }
    return [dict copy];
}

- (void)enqueueAction:(NSString *)action dictionary:(NSMutableDictionary *)payload context:(NSDictionary *)context integrations:(NSDictionary *)integrations
{
    // attach these parts of the payload outside since they are all synchronous
    payload[@"type"] = action;

    [self dispatchBackground:^{
        // attach userId and anonymousId inside the dispatch_async in case
        // they've changed (see identify function)

        // Do not override the userId for an 'alias' action. This value is set in [alias:] already.
        if (![action isEqualToString:@"alias"]) {
            [payload setValue:[SEGState sharedInstance].userInfo.userId forKey:@"userId"];
        }
        [payload setValue:[self.analytics getAnonymousId] forKey:@"anonymousId"];

        [payload setValue:[self integrationsDictionary:integrations] forKey:@"integrations"];

        [payload setValue:[context copy] forKey:@"context"];

        SEGLog(@"%@ Enqueueing action: %@", self, payload);
        
        NSDictionary *queuePayload = [payload copy];
        
        if (self.configuration.experimental.rawSegmentModificationBlock != nil) {
            NSDictionary *tempPayload = self.configuration.experimental.rawSegmentModificationBlock(queuePayload);
            if (tempPayload == nil) {
                SEGLog(@"rawSegmentModificationBlock cannot be used to drop events!");
            } else {
                // prevent anything else from modifying it at this point.
                queuePayload = [tempPayload copy];
            }
        }
        [self queuePayload:queuePayload];
    }];
}

- (void)queuePayload:(NSDictionary *)payload
{
    @try {
        SEGLog(@"Queue is at max capacity (%tu), removing oldest payload.", self.queue.count);
        // Trim the queue to maxQueueSize - 1 before we add a new element.
        trimQueue(self.queue, self.analytics.oneTimeConfiguration.maxQueueSize - 1);
        [self.queue addObject:payload];
        [self persistQueue];
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
    void (^startBatch)(void) = ^{
        NSArray *batch;
        if ([self.queue count] >= maxBatchSize) {
            batch = [self.queue subarrayWithRange:NSMakeRange(0, maxBatchSize)];
        } else {
            batch = [NSArray arrayWithArray:self.queue];
        }
        [self sendData:batch];
    };
    
    [self dispatchBackground:^{
        if ([self.queue count] == 0) {
            SEGLog(@"%@ No queued API calls to flush.", self);
            [self endBackgroundTask];
            return;
        }
        if (self.batchRequest != nil) {
            SEGLog(@"%@ API request already in progress, not flushing again.", self);
            return;
        }
        // here
        startBatch();
    }];
}

- (void)flushQueueByLength
{
    [self dispatchBackground:^{
        SEGLog(@"%@ Length is %lu.", self, (unsigned long)self.queue.count);

        if (self.batchRequest == nil && [self.queue count] >= self.configuration.flushAt) {
            [self flush];
        }
    }];
}

- (void)reset
{
    [self dispatchBackgroundAndWait:^{
#if TARGET_OS_TV
        [self.userDefaultsStorage removeKey:SEGUserIdKey];
        [self.userDefaultsStorage removeKey:SEGTraitsKey];
#else
        [self.fileStorage removeKey:kSEGUserIdFilename];
        [self.fileStorage removeKey:kSEGTraitsFilename];
#endif
        self.userId = nil;
        self.traits = [NSMutableDictionary dictionary];
    }];
}

- (void)notifyForName:(NSString *)name userInfo:(id)userInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:userInfo];
        SEGLog(@"sent notification %@", name);
    });
}

- (void)sendData:(NSArray *)batch
{
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload setObject:iso8601FormattedString([NSDate date]) forKey:@"sentAt"];
    [payload setObject:batch forKey:@"batch"];

    SEGLog(@"%@ Flushing %lu of %lu queued API calls.", self, (unsigned long)batch.count, (unsigned long)self.queue.count);
    SEGLog(@"Flushing batch %@.", payload);

    self.batchRequest = [self.httpClient upload:payload forWriteKey:self.configuration.writeKey completionHandler:^(BOOL retry) {
        void (^completion)(void) = ^{
            if (retry) {
                [self notifyForName:SEGSegmentRequestDidFailNotification userInfo:batch];
                self.batchRequest = nil;
                [self endBackgroundTask];
                return;
            }

            [self.queue removeObjectsInArray:batch];
            [self persistQueue];
            [self notifyForName:SEGSegmentRequestDidSucceedNotification userInfo:batch];
            self.batchRequest = nil;
            [self endBackgroundTask];
        };
        
        [self dispatchBackground:completion];
    }];

    [self notifyForName:SEGSegmentDidSendRequestNotification userInfo:batch];
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
            [self persistQueue];
    }];
}

#pragma mark - Private

- (NSMutableArray *)queue
{
    if (!_queue) {
        _queue = [[self.fileStorage arrayForKey:kSEGQueueFilename] ?: @[] mutableCopy];
    }

    return _queue;
}

- (void)loadTraits
{
    if (![SEGState sharedInstance].userInfo.traits) {
        NSDictionary *traits = nil;
#if TARGET_OS_TV
        traits = [[self.userDefaultsStorage dictionaryForKey:SEGTraitsKey] ?: @{} mutableCopy];
#else
        traits = [[self.fileStorage dictionaryForKey:kSEGTraitsFilename] ?: @{} mutableCopy];
#endif
        [SEGState sharedInstance].userInfo.traits = traits;
    }
}

- (NSUInteger)maxBatchSize
{
    return 100;
}

- (void)loadUserId
{
    NSString *result = nil;
#if TARGET_OS_TV
    result = [[NSUserDefaults standardUserDefaults] valueForKey:SEGUserIdKey];
#else
    result = [self.fileStorage stringForKey:kSEGUserIdFilename];
#endif
    [SEGState sharedInstance].userInfo.userId = result;
}

- (void)persistQueue
{
    [self.fileStorage setArray:[self.queue copy] forKey:kSEGQueueFilename];
}

@end
