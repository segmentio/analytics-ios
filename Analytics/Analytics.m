// Analytics.m
// Copyright 2013 Segment.io

#import "CJSONDataSerializer.h"
#import "Analytics.h"

#define VERSION @"0.0.1"

#define API_URL @"https://api.segment.io/v1/import"

#define DebugLog(...) NSLog(__VA_ARGS__)


@interface Analytics ()

@property(nonatomic,copy)   NSString *secret;
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
            NSLog(@"%@ warning getSharedInstance called before createSharedInstance:", self);
        }
        return sharedInstance;
    }
}

- (id)initialize:(NSString *)secret flushAt:(NSUInteger)flushAt
{
    if (secret == nil) {
        secret = @"";
    }
    if ([secret length] == 0) {
        NSLog(@"%@ warning now", self);
    }
    if (self = [self init]) {
        self.flushAt = flushAt;

        self.secret = secret;
        self.userId = [self getDefaultUserId];
        self.queue = [NSMutableArray array];
    }
    return self;
}

- (void)reset
{
    @synchronized(self) {
        self.userId = [self getDefaultUserId];
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
        [payload setObject:[self formatDate:[NSDate date]] forKey:@"timestamp"];

        DebugLog(@"%@ enqueueing track call: %@", self, payload);
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
        [payload setObject:[self formatDate:[NSDate date]] forKey:@"timestamp"];

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
        
        NSData *payload = [Analytics JSONSerializeObject:payloadDictionary];
        self.connection = [self sendPayload:payload];
    }
}

- (void)cancelFlush
{
    if (self.connection == nil) {
        DebugLog(@"%@ no connection to cancel", self);
    }
    else {
        DebugLog(@"%@ cancelling connection", self);
        [self.connection cancel];
        self.connection = nil;
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
    DebugLog(@"%@ http request: %@", self, [[NSString alloc] initWithData:payload encoding:NSUTF8StringEncoding]);
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




#pragma mark * Utilities

- (NSString *)getDefaultUserId
{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        // For iOS6 and later
        return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    } else {
        // For iOS5 and earlier
        return [[UIDevice currentDevice] uniqueIdentifier];
    }
}

// Formats a date in ISO 8601 http://en.wikipedia.org/wiki/ISO_8601
- (NSString *)formatDate:(NSDate *)date
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormat setLocale:enUSPOSIXLocale];

    NSString *timestamp = [[dateFormat stringFromDate:date] stringByAppendingString:@"Z"];

    [enUSPOSIXLocale release];
    [dateFormat release];

    return timestamp;
}

+ (NSString *)formatDate:(NSDate *)date
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormat setLocale:enUSPOSIXLocale];

    NSString *timestamp = [[dateFormat stringFromDate:date] stringByAppendingString:@"Z"];

    [enUSPOSIXLocale release];
    [dateFormat release];

    return timestamp;
}

+ (NSData *)JSONSerializeObject:(id)obj
{
    id jsonSerializableObject = [Analytics JSONSerializableObjectForObject:obj];

    CJSONDataSerializer *serializer = [CJSONDataSerializer serializer];
    NSError *error = nil;
    NSData *data = nil;
    @try {
        data = [serializer serializeObject:jsonSerializableObject error:&error];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ exception serializing api data to json: %@", self, exception);
    }
    if (error) {
        NSLog(@"%@ error serializing api data to json: %@", self, error);
    }
    return data;
}

+ (id)JSONSerializableObjectForObject:(id)obj
{
    // already valid json!
    if ([obj isKindOfClass:[NSString class]] ||
        [obj isKindOfClass:[NSNumber class]] ||
        [obj isKindOfClass:[NSNull class]]) {
        return obj;
    }

    // urls (to strings)
    if ([obj isKindOfClass:[NSURL class]]) {
        return [obj absoluteString];
    }

    // dates (to strings)
    if ([obj isKindOfClass:[NSDate class]]) {
        return [self formatDate:obj];
    }

    // arrays (iterate and convert)
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        for (id nestedObj in obj) {
            [array addObject:[Analytics JSONSerializableObjectForObject:nestedObj]];
        }
        return [NSArray arrayWithArray:array];
    }

    // dictionaries (iterate and convert)
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (id key in obj) {
            NSString *keyStr;
            if (![key isKindOfClass:[NSString class]]) {
                keyStr = [key description];
                NSLog(@"%@ warning! object keys should be strings. got %@, instead forcing it to be %@", self, [key class], keyStr);
            } else {
                keyStr = [NSString stringWithString:key];
            }
            id value = [Analytics JSONSerializableObjectForObject:[obj objectForKey:key]];
            [dict setObject:value forKey:keyStr];
        }
        return [NSDictionary dictionaryWithDictionary:dict];
    }

    // fallback to the description
    NSString *str = [obj description];
    NSLog(@"%@ warning! objects should be valid json types. got %@, instead forcing it to be %@", self, [obj class], str);
    return str;
}




#pragma mark * NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<Analytics: %p %@>", self, self.secret];
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
