// SegmentioProvider.m
// Copyright 2013 Segment.io

#import "Analytics.h"
#import "AnalyticsUtils.h"
#import "AnalyticsJSONRequest.h"
#import "SegmentioProvider.h"

#define SEGMENTIO_API_URL [NSURL URLWithString:@"https://api.segment.io/v1/import"]
#define SEGMENTIO_MAX_BATCH_SIZE 100

static NSString * const kSessionID = @"kSegmentioSessionID";

static NSString *ToISO8601(NSDate *date) {
    static dispatch_once_t dateFormatToken;
    static NSDateFormatter *dateFormat;
    dispatch_once(&dateFormatToken, ^{
        dateFormat = [[NSDateFormatter alloc] init];
        dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS";
        dateFormat.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        dateFormat.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    });
    return [[dateFormat stringFromDate:date] stringByAppendingString:@"Z"];
}

static NSString *GetSessionID(BOOL reset) {
    // We've chosen to generate a UUID rather than use the UDID (deprecated in iOS 5),
    // identifierForVendor (iOS6 and later, can't be changed on logout),
    // or MAC address (blocked in iOS 7). For more info see https://segment.io/libraries/ios#ids
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults stringForKey:kSessionID] || reset) {
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef string = CFUUIDCreateString(NULL, theUUID);
        SOLog(@"New SessionID: %@", string);
        CFRelease(theUUID);
        [defaults setObject:(__bridge_transfer NSString *)string forKey:kSessionID];
    }
    return [defaults stringForKey:kSessionID];
}

static NSMutableDictionary *CreateContext(NSDictionary *parameters) {
    NSMutableDictionary *context = [NSMutableDictionary dictionary];
    [context setValue:@"analytics-ios" forKey:@"library"];
    // TODO add any device information here
    if (parameters != nil) {
        [context addEntriesFromDictionary:parameters];
    }
    return context;
}

@interface SegmentioProvider () <AnalyticsJSONRequestDelegate>

@property (nonatomic, weak) Analytics *analytics;
@property (nonatomic, strong) NSTimer *flushTimer;
@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic, strong) NSArray *batch;
@property (nonatomic, strong) AnalyticsJSONRequest *request;

@end


@implementation SegmentioProvider {
    dispatch_queue_t _serialQueue;
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
        _queue = [NSMutableArray array];
        _flushTimer = [NSTimer scheduledTimerWithTimeInterval:self.flushAfter
                                                       target:self
                                                     selector:@selector(flush)
                                                     userInfo:nil
                                                      repeats:YES];
        _serialQueue = dispatch_queue_create("io.segment.analytics.segmentio", DISPATCH_QUEUE_SERIAL);
        self.name = @"Segment.io";
        self.valid = NO;
        self.initialized = NO;
        self.settings = [NSDictionary dictionaryWithObjectsAndKeys:secret, @"secret", nil];
        [self validate];
        self.initialized = YES;

    }
    return self;
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


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context {
    dispatch_async(_serialQueue, ^{
        self.userId = userId;
    });

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
    NSMutableDictionary *providersDict = [context[@"providers"] ?: @{} mutableCopy];
    for (AnalyticsProvider *provider in self.analytics.providers)
        if (![provider isKindOfClass:[SegmentioProvider class]])
            providersDict[provider.name] = @NO;
    NSMutableDictionary *serverContext = [context mutableCopy];
    serverContext[@"providers"] = providersDict;
    return serverContext;
}

- (void)enqueueAction:(NSString *)action dictionary:(NSMutableDictionary *)dictionary context:(NSDictionary *)context {
    // attach these parts of the payload outside since they are all synchronous
    // and the timestamp will be more accurate.
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    [payload setValue:action forKey:@"action"];
    [payload setValue:ToISO8601([NSDate date]) forKey:@"timestamp"];
    [payload addEntriesFromDictionary:dictionary];
    [payload setValue:CreateContext(context) forKey:@"context"];
    
    context = [self serverContextForContext:context];

    dispatch_async(_serialQueue, ^{

        // attach userId and sessionId inside the dispatch_async in case
        // they've changed (see identify function)
        [payload setValue:self.userId forKey:@"userId"];
        [payload setValue:self.sessionId forKey:@"sessionId"];

        SOLog(@"%@ Enqueueing action: %@", self, payload);

        [self.queue addObject:payload];
        
        [self flushQueueByLength];
    });
}

- (void)flush
{
    dispatch_async(_serialQueue, ^{
        if ([self.queue count] == 0) {
            SOLog(@"%@ No queued API calls to flush.", self);
            return;
        }
        else if (self.request != nil) {
            SOLog(@"%@ API request already in progress, not flushing again.", self);
            return;
        }
        else if ([self.queue count] >= SEGMENTIO_MAX_BATCH_SIZE) {
            self.batch = [self.queue subarrayWithRange:NSMakeRange(0, SEGMENTIO_MAX_BATCH_SIZE)];
        }
        else {
            self.batch = [NSArray arrayWithArray:self.queue];
        }

        SOLog(@"%@ Flushing %lu of %lu queued API calls.", self, (unsigned long)self.batch.count, (unsigned long)self.queue.count);

        NSMutableDictionary *payloadDictionary = [NSMutableDictionary dictionary];
        [payloadDictionary setObject:self.secret forKey:@"secret"];
        [payloadDictionary setObject:self.batch forKey:@"batch"];
        
        NSData *payload = [NSJSONSerialization dataWithJSONObject:payloadDictionary
                                                          options:0 error:NULL];
        [self sendData:payload];
    });
}

- (void)flushQueueByLength
{
    dispatch_async(_serialQueue, ^{
        SOLog(@"%@ Length is %lu.", self, (unsigned long)self.queue.count);
        if (self.request == nil && [self.queue count] >= self.flushAt) {
            [self flush];
        }
    });
}

- (void)reset
{
    [self.flushTimer invalidate];
    self.flushTimer = nil;
    self.flushTimer = [NSTimer scheduledTimerWithTimeInterval:self.flushAfter
                                                       target:self
                                                     selector:@selector(flush)
                                                     userInfo:nil
                                                      repeats:YES];
    dispatch_async(_serialQueue, ^{
        self.sessionId = GetSessionID(YES); // changes the UUID
        self.userId = nil;
        self.queue = [NSMutableArray array];
    });
}

#pragma mark - Connection delegate callbacks

- (void)sendData:(NSData *)data {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:SEGMENTIO_API_URL];
        [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest setHTTPBody:data];
        SOLog(@"%@ Sending batch API request: %@", self,
              [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        self.request = [AnalyticsJSONRequest startRequestWithURLRequest:urlRequest delegate:self];
    });
}

#pragma mark - AnalyticsJSONRequest Delegate

- (void)requestDidComplete:(AnalyticsJSONRequest *)request {
    dispatch_async(_serialQueue, ^{
        if (request.error) {
            SOLog(@"%@ API request had an error: %@", self, request.error);
        } else {
            SOLog(@"%@ API request success 200", self);
            // TODO
            // Currently we don't retry sending any of the queued calls. If they return
            // with a response code other than 200 we still remove them from the queue.
            // Is that the desired behavior? Suggestion: (retry if network error or 500 error. But not 400 error)
            [self.queue removeObjectsInArray:self.batch];
        }
        
        self.batch = nil;
        self.request = nil;
    });
}

#pragma mark - Class Methods

+ (void)load {
    [Analytics registerProvider:self withIdentifier:@"Segment.io"];
}

@end
