// AnalyticsRequest.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#define AssertMainThread() NSCParameterAssert([NSThread isMainThread])

#import "SEGAnalyticsRequest.h"


@interface SEGAnalyticsRequest () <NSURLConnectionDataDelegate> {
    NSMutableData *_responseData;
}

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURLRequest *urlRequest;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSData *responseData;
@property (nonatomic, strong) id responseJSON;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSIndexSet *acceptableStatusCodes;

@end


@implementation SEGAnalyticsRequest

- (id)initWithURLRequest:(NSURLRequest *)urlRequest
{
    if (self = [super init]) {
        _urlRequest = urlRequest;
    }
    return self;
}

- (void)start
{
    self.connection = [[NSURLConnection alloc] initWithRequest:self.urlRequest
                                                      delegate:self
                                              startImmediately:NO];
    [self.connection setDelegateQueue:[[self class] networkQueue]];
    [self.connection start];
}

- (void)finish
{
    if (self.completion)
        self.completion();
}

#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.response = (NSHTTPURLResponse *)response;
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSInteger statusCode = self.response.statusCode;
    if ([self.acceptableStatusCodes containsIndex:statusCode]) {
        NSError *error = nil;
        if (self.responseData.length > 0) {
            self.responseJSON = [NSJSONSerialization JSONObjectWithData:self.responseData
                                                                options:0
                                                                  error:&error];
            self.error = error;
        }
    } else {
        self.error = [NSError errorWithDomain:@"HTTP"
                                         code:statusCode
                                     userInfo:@{ NSLocalizedDescriptionKey :
                                                     [NSString stringWithFormat:@"HTTP Error %ld", (long)statusCode] }];
    }
    [self finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.error = error;
    [self finish];
}

#pragma mark - Class Methods

+ (instancetype)startWithURLRequest:(NSURLRequest *)urlRequest
                         completion:(SEGAnalyticsRequestCompletionBlock)completion
{
    SEGAnalyticsRequest *request = [[self alloc] initWithURLRequest:urlRequest];
    request.completion = completion;
    [request start];
    return request;
}

+ (NSOperationQueue *)networkQueue
{
    static dispatch_once_t onceToken;
    static NSOperationQueue *networkQueue;
    dispatch_once(&onceToken, ^{
        networkQueue = [[NSOperationQueue alloc] init];
    });
    return networkQueue;
}

#pragma mark - Private

- (NSIndexSet *)acceptableStatusCodes
{
    if (!_acceptableStatusCodes) {
        _acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    }
    return _acceptableStatusCodes;
}

@end
