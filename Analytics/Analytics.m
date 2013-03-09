// Analytics.m
// Copyright 2013 Segment.io

#import "DateFormat8601.h"
#import "JSONSerializeObject.h"
#import "UniqueIdentifier.h"

#import "Analytics.h"

#define VERSION @"0.0.1"
#define API_URL @"https://api.segment.io/v1/import"

#define DebugLog(...) NSLog(__VA_ARGS__)


@interface Analytics ()

@property(nonatomic,copy)   NSString *secret;
@property(nonatomic,copy)   NSString *userId;
@property(nonatomic,retain) NSUInteger flushAt;
@property(nonatomic,retain) NSMutableArray *queue;
@property(nonatomic,retain) NSArray *batch;
@property(nonatomic,retain) NSURLConnection *connection;
@property(nonatomic,retain) NSMutableData *responseData;

@end



@implementation Analytics

static Analytics *sharedInstance = nil;

#pragma mark * Initializiation

+ (id)createSharedInstance:(NSString *)secret
{
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[super alloc] initialize:secret flushAt:20];
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

        DebugLog(@"%@ enqueueing identify call: %@", self, payload);
        [self.queue addObject:payload];
    }
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

        DebugLog(@"%@ enqueueing track call: %@", self, payload);
        [self.queue addObject:payload];
    }
}




#pragma mark * Queueing

- (void)flush
{
    @synchronized(self) {
        if ([self.queue count] == 0) {
            DebugLog(@"%@ no queued API calls to flush", self);
            return;
        }
        else if (self.connection != nil) {
            DebugLog(@"%@ connection already open", self);
            return;
        }
        else if ([self.queue count] > self.flushAt) {
            self.batch = [self.queue subarrayWithRange:NSMakeRange(0, self.flushAt)];
        }
        else {
            self.batch = [NSArray arrayWithArray:self.queue];
        }

        DebugLog(@"%@ flushing %u of %u queued API calls.", self, self.batch.count, self.queue.count);

        NSMutableDictionary *payloadDictionary = [NSMutableDictionary dictionary];

        [payloadDictionary setObject:self.secret forKey:@"secret"];
        [payloadDictionary setObject:self.batch forKey:@"batch"];
        
        NSData *payload = [JSONSerializeObject serialize:payloadDictionary];
        self.connection = [self sendPayload:payload];
    }
}




#pragma mark * Connection delegate callbacks

- (NSURLConnection *)sendPayload:(NSData *)payload
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:API_URL]];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:payload];
    DebugLog(@"%@ api request: %@", self, [[NSString alloc] initWithData:payload encoding:NSUTF8StringEncoding]);
    return [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    DebugLog(@"%@ http status code: %d", self, [response statusCode]);
    if ([response statusCode] != 200) {
        NSLog(@"%@ http error: %@", self, [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]]);
    }
    else {
        self.responseData = [NSMutableData data];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    @synchronized(self) {
        NSLog(@"%@ network failure: %@", self, error);

        self.batch = nil;
        self.responseData = nil;
        self.connection = nil;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    @synchronized(self) {
        DebugLog(@"%@ http response finished loading", self);

        NSString *response = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
        if ([response intValue] == 0) {
            NSLog(@"%@ track api error: %@", self, response);
        }
        [response release];

        [self.queue removeObjectsInArray:self.batch];

        self.batch = nil;
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
