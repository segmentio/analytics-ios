// Analytics.m
// Copyright 2013 Segment.io

#import "Analytics.h"

// Uncomment this line to turn on debug logging
#define ANALYTICS_DEBUG_MODE

#ifdef ANALYTICS_DEBUG_MODE
#define AnalyticsDebugLog(...) NSLog(__VA_ARGS__)
#else
#define AnalyticsDebugLog(...)
#endif

#define ANALYTICS_VERSION @"0.0.1"
#define ANALYTICS_API_URL @"https://api.segment.io/v1/import"

static const NSString * const kSessionID = @"kAnalyticsSessionID";

static NSString *ToISO8601(NSDate *date) {
    static dispatch_once_t onceToken;
    static NSDateFormatter *dateFormat;
    dispatch_once(&onceToken, ^{
        dateFormat = [[NSDateFormatter alloc] init];
        dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
        dateFormat.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        dateFormat.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    });
    return [[dateFormat stringFromDate:date] stringByAppendingString:@"Z"];
}

static NSString *GetSessionID() {
#if TARGET_OS_MAC
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
#else
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        // For iOS6 and later
        return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    } else {
        // For iOS5 and earlier
        return [[UIDevice currentDevice] uniqueIdentifier];
    }
#endif
}

@interface Analytics ()

@property(nonatomic, strong) NSString *secret;
@property(nonatomic, strong) NSString *userId;
@property(nonatomic, strong) NSString *sessionId;
@property(nonatomic, assign) NSUInteger flushAt;
@property(nonatomic, assign) NSUInteger flushAfter;

@property(nonatomic, strong) NSTimer *flushTimer;
@property(nonatomic, strong) NSMutableArray *queue;
@property(nonatomic, strong) NSArray *batch;
@property(nonatomic, strong) NSURLConnection *connection;
@property(nonatomic, assign) NSInteger responseCode;
@property(nonatomic, strong) NSMutableData *responseData;

@end


@implementation Analytics

static Analytics *sharedInstance = nil;

#pragma mark - Initializiation

+ (id)createSharedInstance:(NSString *)secret
{
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[super alloc] initWithSecret:secret flushAt:20 flushAfter:60];
        }
        return sharedInstance;
    }
}

+ (id)getSharedInstance
{
    @synchronized(self) {
        if (sharedInstance == nil) {
            NSLog(@"%@ WARNING getSharedInstance called before createSharedInstance.", self);
        }
        return sharedInstance;
    }
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
    }
    return self;
}

- (void)reset
{
    @synchronized(self) {
        self.sessionId = GetSessionID();
        self.queue = [NSMutableArray array];
    }
}

#pragma mark - Analytics API


- (void)identify:(NSString *)userId
{
    [self identify:userId traits:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits
{
    if (!userId.length) {
        NSLog(@"%@ identify requires an userId.", self);
        return;
    }
    @synchronized(self) {
        self.userId = userId;

        NSMutableDictionary *payload = [NSMutableDictionary dictionary];
        [payload setValue:@"identify" forKey:@"action"];
        [payload setValue:self.userId forKey:@"userId"];
        [payload setValue:self.sessionId forKey:@"sessionId"];
        [payload setValue:traits forKey:@"traits"];
        [payload setValue:ToISO8601([NSDate date]) forKey:@"timestamp"];

        AnalyticsDebugLog(@"%@ Enqueueing identify call: %@", self, payload);

        [self.queue addObject:payload];
    }

    [self flushQueueByLength];
}


- (void)track:(NSString *)event
{
    [self track:event properties:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties
{
    if (!event.length == 0) {
        NSLog(@"%@ track requires an event name.", self);
        return;
    }
    @synchronized(self) {

        NSMutableDictionary *payload = [NSMutableDictionary dictionary];
        [payload setValue:@"track" forKey:@"action"];
        [payload setValue:self.userId forKey:@"userId"];
        [payload setValue:self.sessionId forKey:@"userId"];
        [payload setValue:event forKey:@"event"];
        [payload setValue:properties forKey:@"properties"];
        [payload setValue:ToISO8601([NSDate date]) forKey:@"timestamp"];

        AnalyticsDebugLog(@"%@ Enqueueing track call: %@", self, payload);

        [self.queue addObject:payload];
    }

    [self flushQueueByLength];
}

#pragma mark - Queueing

- (void)flush
{
    @synchronized(self) {
        if ([self.queue count] == 0) {
            AnalyticsDebugLog(@"%@ No queued API calls to flush.", self);
            return;
        }
        else if (self.connection != nil) {
            AnalyticsDebugLog(@"%@ API request already in progress, not flushing again.", self);
            return;
        }
        else if ([self.queue count] >= self.flushAt) {
            self.batch = [self.queue subarrayWithRange:NSMakeRange(0, self.flushAt)];
        }
        else {
            self.batch = [NSArray arrayWithArray:self.queue];
        }

        AnalyticsDebugLog(@"%@ Flushing %u of %u queued API calls.", self, self.batch.count, self.queue.count);

        NSMutableDictionary *payloadDictionary = [NSMutableDictionary dictionary];
        [payloadDictionary setObject:self.secret forKey:@"secret"];
        [payloadDictionary setObject:self.batch forKey:@"batch"];
        
        NSData *payload = [NSJSONSerialization dataWithJSONObject:payloadDictionary
                                                          options:0 error:NULL];
        self.connection = [self sendPayload:payload];
    }
}

- (void)flushQueueByLength
{
    BOOL flushQueue = NO;
    @synchronized(self) {
        if (self.connection == nil && [self.queue count] >= self.flushAt) {
            flushQueue = YES;
        }
        AnalyticsDebugLog(@"%@ Length is %u. Flushing? %@.", self, [self.queue count], flushQueue ? @"Yes" : @"No");
    }
    
    if (flushQueue == YES) {
        [self flush];
    }
}

#pragma mark - Connection delegate callbacks

- (NSURLConnection *)sendPayload:(NSData *)payload
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:ANALYTICS_API_URL]];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:payload];

    AnalyticsDebugLog(@"%@ Sending batch API request: %@", self, [[NSString alloc] initWithData:payload encoding:NSUTF8StringEncoding]);

    return [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    self.responseCode = [response statusCode];
    self.responseData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    @synchronized(self) {

        if (self.responseCode != 200) {
            NSLog(@"%@ API request had an error: %@", self, [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding]);
        }
        else {
            NSLog(@"%@ API request success 200", self);
        }

        // TODO
        // Currently we don't retry sending any of the queued calls. If they return 
        // with a response code other than 200 we still remove them from the queue.
        // Is that the desired behavior?
        [self.queue removeObjectsInArray:self.batch];

        self.batch = nil;
        self.responseCode = nil;
        self.responseData = nil;
        self.connection = nil;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    @synchronized(self) {
        NSLog(@"%@ Network failed while sending API request: %@", self, error);

        self.batch = nil;
        self.responseCode = nil;
        self.responseData = nil;
        self.connection = nil;
    }
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
