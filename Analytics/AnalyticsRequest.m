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

@property (nonatomic, strong) AnalyticsRequestCompletionBlock completion;
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
    AssertMainThread();
    self.connection = [[NSURLConnection alloc] initWithRequest:self.urlRequest
                                                      delegate:self
                                              startImmediately:YES];
}

- (void)finish {
    if (self.completion)
        self.completion();
}

#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    AssertMainThread();
    self.response = (NSHTTPURLResponse *)response;
    self.responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    AssertMainThread();
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    AssertMainThread();
    int statusCode = self.response.statusCode;
    if (statusCode >= 200 && statusCode < 300) {
        NSError *error = nil;
        self.responseJSON = [NSJSONSerialization JSONObjectWithData:self.responseData
                                                            options:0
                                                              error:&error];
        self.error = error;
    } else {
        self.error = [NSError errorWithDomain:@"HTTP"
                                         code:statusCode
                                     userInfo:@{NSLocalizedDescriptionKey:
                        [NSString stringWithFormat:@"HTTP Error %d", statusCode]}];

    }
    [self finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    AssertMainThread();
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

@end
