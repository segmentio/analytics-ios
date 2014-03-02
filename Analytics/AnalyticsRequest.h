// AnalyticsRequest.h
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Foundation/Foundation.h>

typedef void (^AnalyticsRequestCompletionBlock)(void);

@interface AnalyticsRequest : NSObject

@property (nonatomic, copy) AnalyticsRequestCompletionBlock completion;
@property (nonatomic, readonly) NSURLRequest *urlRequest;
@property (nonatomic, readonly) NSHTTPURLResponse *response;
@property (nonatomic, readonly) NSMutableData *responseData;
@property (nonatomic, readonly) id responseJSON;
@property (nonatomic, readonly) NSError *error;

+ (instancetype)startWithURLRequest:(NSURLRequest *)urlRequest
                         completion:(AnalyticsRequestCompletionBlock)completion;

@end
