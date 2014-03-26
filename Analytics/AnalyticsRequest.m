//
//  AnalyticsRequest.m
//  Analytics
//
//  Created by Tony Xiao on 8/19/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#define AssertMainThread() NSAssert([NSThread isMainThread], @"%s must be called form main thread", __func__)

#import "AnalyticsRequest.h"

@interface AnalyticsRequest () <NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURLRequest *urlRequest;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) id responseJSON;
@property (nonatomic, strong) NSError *error;

@end

@implementation AnalyticsRequest

- (id)initWithURLRequest:(NSURLRequest *)urlRequest {
    if (self = [super init]) {
        _urlRequest = urlRequest;
    }
    return self;
}

- (void)start {
    self.connection = [[NSURLConnection alloc] initWithRequest:self.urlRequest
                                                      delegate:self
                                              startImmediately:NO];
    [self.connection setDelegateQueue:[[self class] networkQueue]];
    [self.connection start];
}

- (void)finish {
    if (self.completion)
        self.completion();
}

#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.response = (NSHTTPURLResponse *)response;
    self.responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSInteger statusCode = self.response.statusCode;
    if (statusCode >= 200 && statusCode < 300) {
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
                                     userInfo:@{NSLocalizedDescriptionKey:
                        [NSString stringWithFormat:@"HTTP Error %ld", (long)statusCode]}];

    }
    [self finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.error = error;
    [self finish];
}

#pragma mark Class Methods

+ (instancetype)startWithURLRequest:(NSURLRequest *)urlRequest
                         completion:(AnalyticsRequestCompletionBlock)completion {
    AnalyticsRequest *request = [[self alloc] initWithURLRequest:urlRequest];
    request.completion = completion;
    [request start];
    return request;
}

+ (NSOperationQueue *)networkQueue {
    static dispatch_once_t onceToken;
    static NSOperationQueue *networkQueue;
    dispatch_once(&onceToken, ^{
        networkQueue = [[NSOperationQueue alloc] init];
    });
    return networkQueue;
}

@end
