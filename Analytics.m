// Analytics.m
// Copyright 2013 Segment.io

#import "Analytics.h"

#ifdef DEBUG
#define ANALYTICS_DEBUG_MODE
#endif

#ifdef ANALYTICS_DEBUG_MODE
#define AnalyticsDebugLog(...) NSLog(__VA_ARGS__)
#else
#define AnalyticsDebugLog(...)
#endif

#define ANALYTICS_VERSION @"0.0.5"
#define ANALYTICS_API_URL [NSURL URLWithString:@"https://api.segment.io/v1/import"]
#define ANALYTICS_MAX_BATCH_SIZE 100



static NSString * const kSessionID = @"kAnalyticsSessionID";

static NSString *ToISO8601(NSDate *date) {
    static dispatch_once_t dateFormatToken;
    static NSDateFormatter *dateFormat;
    dispatch_once(&dateFormatToken, ^{
        dateFormat = [[NSDateFormatter alloc] init];
        dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
        dateFormat.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        dateFormat.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    });
    return [[dateFormat stringFromDate:date] stringByAppendingString:@"Z"];
}

static NSString *GetSessionIDFromDefaults() {
    // We could use serial number or mac address (see http://developer.apple.com/library/mac/#technotes/tn1103/_index.html )
    // But it's really not necessary since they can be nil and we are only using them as SessionID anyways
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults stringForKey:kSessionID]) {
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef string = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        [defaults setObject:(__bridge_transfer NSString *)string forKey:kSessionID];
    }
    return [defaults stringForKey:kSessionID];
}

static NSString *GetSessionID() {
#if TARGET_OS_MAC
    return GetSessionIDFromDefaults();
#else
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        // For iOS6 and later
        return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    } else {
        // For iOS5 and earlier
        // As of May 1, 2013 we cannot use UDIDs 
        // see https://developer.apple.com/news/?id=3212013a
        // so we use a generated UUID that we save to NSUserDefaults
        return GetSessionIDFromDefaults();
    }
#endif
}




@interface Analytics ()

@property(nonatomic, strong) NSTimer *flushTimer;
@property(nonatomic, strong) NSMutableArray *queue;
@property(nonatomic, strong) NSArray *batch;
@property(nonatomic, strong) NSURLConnection *connection;
@property(nonatomic, assign) NSInteger responseCode;
@property(nonatomic, strong) NSMutableData *responseData;

@end




@implementation Analytics {
    dispatch_queue_t _serialQueue;
}

static Analytics *sharedAnalytics = nil;



#pragma mark - Initializiation

+ (instancetype)sharedAnalyticsWithSecret:(NSString *)secret
{
    return [self sharedAnalyticsWithSecret:secret flushAt:20 flushAfter:30];
}

+ (instancetype)sharedAnalyticsWithSecret:(NSString *)secret flushAt:(NSUInteger)flushAt flushAfter:(NSUInteger)flushAfter
{
    NSParameterAssert(secret.length > 0);
    NSParameterAssert(flushAt > 0);
    NSParameterAssert(flushAfter > 0);

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAnalytics = [[self alloc] initWithSecret:secret flushAt:flushAt flushAfter:flushAfter];
    });
    return sharedAnalytics;
}

+ (instancetype)sharedAnalytics
{
    NSAssert(sharedAnalytics, @"%@ sharedAnalytics called before sharedAnalyticsWithSecret", self);
    return sharedAnalytics;
}

- (id)initWithSecret:(NSString *)secret flushAt:(NSUInteger)flushAt flushAfter:(NSUInteger)flushAfter
{
    NSParameterAssert(secret.length);
    
    if (self = [self init]) {
        _flushAt = flushAt;
        _flushAfter = flushAfter;
        _secret = secret;
        _sessionId = GetSessionID();
        _queue = [NSMutableArray array];
        _flushTimer = [NSTimer scheduledTimerWithTimeInterval:self.flushAfter
                                                       target:self
                                                     selector:@selector(flush)
                                                     userInfo:nil
                                                      repeats:YES];
        _serialQueue = dispatch_queue_create("io.segment.analytics", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}



#pragma mark - Analytics API


- (void)identify:(NSString *)userId
{
    [self identify:userId traits:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits
{
    dispatch_async(_serialQueue, ^{
        self.userId = userId;
    });

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:traits forKey:@"traits"];

    [self enqueueAction:@"identify" dictionary:dictionary];
}


- (void)track:(NSString *)event
{
    [self track:event properties:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties
{
    NSAssert(event.length, @"%@ track requires an event name.", self);

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:event forKey:@"event"];
    [dictionary setValue:properties forKey:@"properties"];
    
    [self enqueueAction:@"track" dictionary:dictionary];
}



#pragma mark - Queueing

- (void)enqueueAction:(NSString *)action dictionary:(NSMutableDictionary *)dictionary
{
    // attach these parts of the payload outside since they are all synchronous
    // and the timestamp will be more accurate.
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    [payload setValue:action forKey:@"action"];
    [payload setValue:ToISO8601([NSDate date]) forKey:@"timestamp"];
    [payload addEntriesFromDictionary:dictionary];

    dispatch_async(_serialQueue, ^{

        // attach userId and sessionId inside the dispatch_async in case
        // they've changed (see identify function)
        [payload setValue:self.userId forKey:@"userId"];
        [payload setValue:self.sessionId forKey:@"sessionId"];

        AnalyticsDebugLog(@"%@ Enqueueing action: %@", self, payload);

        [self.queue addObject:payload];
        
        [self flushQueueByLength];
    });
}

- (void)flush
{
    dispatch_async(_serialQueue, ^{
        if ([self.queue count] == 0) {
            AnalyticsDebugLog(@"%@ No queued API calls to flush.", self);
            return;
        }
        else if (self.connection != nil) {
            AnalyticsDebugLog(@"%@ API request already in progress, not flushing again.", self);
            return;
        }
        else if ([self.queue count] >= ANALYTICS_MAX_BATCH_SIZE) {
            self.batch = [self.queue subarrayWithRange:NSMakeRange(0, ANALYTICS_MAX_BATCH_SIZE)];
        }
        else {
            self.batch = [NSArray arrayWithArray:self.queue];
        }

        AnalyticsDebugLog(@"%@ Flushing %lu of %lu queued API calls.", self, self.batch.count, self.queue.count);

        NSMutableDictionary *payloadDictionary = [NSMutableDictionary dictionary];
        [payloadDictionary setObject:self.secret forKey:@"secret"];
        [payloadDictionary setObject:self.batch forKey:@"batch"];
        
        NSData *payload = [NSJSONSerialization dataWithJSONObject:payloadDictionary
                                                          options:0 error:NULL];
        self.connection = [self connectionForPayload:payload];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.connection start];
        });
    });
}

- (void)flushQueueByLength
{
    dispatch_async(_serialQueue, ^{
        AnalyticsDebugLog(@"%@ Length is %lu.", self, [self.queue count]);
        if (self.connection == nil && [self.queue count] >= self.flushAt)
            [self flush];
    });
}

- (void)reset
{
    dispatch_async(_serialQueue, ^{
        self.sessionId = GetSessionID();
        self.queue = [NSMutableArray array];
    });
}



#pragma mark - Connection delegate callbacks

- (NSURLConnection *)connectionForPayload:(NSData *)payload
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:ANALYTICS_API_URL];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:payload];
    
    AnalyticsDebugLog(@"%@ Sending batch API request: %@", self,
                      [[NSString alloc] initWithData:payload encoding:NSUTF8StringEncoding]);
    
    return [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    NSAssert([NSThread isMainThread], @"Should be on main since URL connection should have started on main");
    self.responseCode = [response statusCode];
    self.responseData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSAssert([NSThread isMainThread], @"Should be on main since URL connection should have started on main");
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    dispatch_async(_serialQueue, ^{

        if (self.responseCode != 200) {
            NSLog(@"%@ API request had an error: %@", self, [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding]);
        }
        else {
            AnalyticsDebugLog(@"%@ API request success 200", self);
        }

        // TODO
        // Currently we don't retry sending any of the queued calls. If they return 
        // with a response code other than 200 we still remove them from the queue.
        // Is that the desired behavior? Suggestion: (retry if network error or 500 error. But not 400 error)
        [self.queue removeObjectsInArray:self.batch];

        self.batch = nil;
        self.responseCode = 0;
        self.responseData = nil;
        self.connection = nil;
    });
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    dispatch_async(_serialQueue, ^{
        NSLog(@"%@ Network failed while sending API request: %@", self, error);

        self.batch = nil;
        self.responseCode = 0;
        self.responseData = nil;
        self.connection = nil;
    });
}



#pragma mark - NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<Analytics secret:%@>", self.secret];
}

- (void)dealloc
{
    [self.flushTimer invalidate];
}

@end
