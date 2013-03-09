// Analytics.m
// Copyright 2013 Segment.io

#import "DateFormat8601.h"
#import "JSONSerializeObject.h"
#import "UniqueIdentifier.h"

#import "Analytics.h"

#define ANALYTICS_VERSION @"0.0.1"
#define ANALYTICS_API_URL @"https://api.segment.io/v1/import"

// Uncomment this line to turn on debug logging
#define ANALYTICS_DEBUG_MODE

#ifdef ANALYTICS_DEBUG_MODE
#define AnalyticsDebugLog(...) NSLog(__VA_ARGS__)
#else
#define AnalyticsDebugLog(...)
#endif


@interface Analytics ()

@property(nonatomic,copy)   NSString *secret;
@property(nonatomic,copy)   NSString *userId;
@property(nonatomic,assign) NSUInteger flushAt;
@property(nonatomic,retain) NSMutableArray *queue;
@property(nonatomic,retain) NSArray *batch;
@property(nonatomic,retain) NSURLConnection *connection;
@property(nonatomic,assign) NSInteger responseCode;
@property(nonatomic,retain) NSMutableData *responseData;

@end



@implementation Analytics

static Analytics *sharedInstance = nil;

#pragma mark * Initializiation

+ (id)createSharedInstance:(NSString *)secret
{
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[super alloc] initialize:secret flushAt:2];
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

- (id)initialize:(NSString *)secret flushAt:(NSUInteger)flushAt
{
    if (secret == nil || [secret length] == 0) {
        NSLog(@"%@ WARNING invalid secret was nil or empty string.", self);
        return nil;
    }

    self = [self init];
    self.flushAt = flushAt;
    self.secret = secret;
    self.userId = [UniqueIdentifier getUniqueIdentifier];
    self.queue = [NSMutableArray array];

    return self;
}

- (void)reset
{
    @synchronized(self) {
        self.userId = [UniqueIdentifier getUniqueIdentifier];
        self.queue = [NSMutableArray array];
    }
}




#pragma mark * Analytics API


- (void)identify:(NSString *)userId
{
    [self identify:userId traits:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits
{
    @synchronized(self) {

        if (userId != nil) {
            self.userId = userId;
        }

        NSMutableDictionary *payload = [NSMutableDictionary dictionary];

        [payload setObject:@"identify" forKey:@"action"];
        [payload setObject:self.userId forKey:@"userId"];
        if (traits != nil) {
            [payload setObject:traits forKey:@"traits"];
        }
        [payload setObject:[DateFormat8601 formatDate:[NSDate date]] forKey:@"timestamp"];

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
    @synchronized(self) {

        if (event == nil || [event length] == 0) {
            NSLog(@"%@ track requires an event name.", self);
            return;
        }

        NSMutableDictionary *payload = [NSMutableDictionary dictionary];

        [payload setObject:@"track" forKey:@"action"];
        [payload setObject:self.userId forKey:@"userId"];
        [payload setObject:event forKey:@"event"];
        if (properties != nil) {
            [payload setObject:properties forKey:@"properties"];
        }
        [payload setObject:[DateFormat8601 formatDate:[NSDate date]] forKey:@"timestamp"];

        AnalyticsDebugLog(@"%@ Enqueueing track call: %@", self, payload);
        [self.queue addObject:payload];
    }

    [self flushQueueByLength];
}




#pragma mark * Queueing

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
        
        NSData *payload = [JSONSerializeObject serialize:payloadDictionary];
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




#pragma mark * Connection delegate callbacks

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




#pragma mark * NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<Analytics secret:%@>", self.secret];
}

- (void)dealloc
{
    
    self.secret = nil;
    self.userId = nil;
    self.queue = nil;
    self.batch = nil;
    self.connection = nil;
    self.responseData = nil;
    
    [super dealloc];
}

@end
