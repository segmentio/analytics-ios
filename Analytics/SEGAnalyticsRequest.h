// AnalyticsRequest.h
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Foundation/Foundation.h>

typedef void (^SEGAnalyticsRequestCompletionBlock)(void);


@interface SEGAnalyticsRequest : NSObject

@property (nonatomic, copy) SEGAnalyticsRequestCompletionBlock completion;
@property (nonatomic, readonly) NSURLRequest *urlRequest;
@property (nonatomic, readonly) NSHTTPURLResponse *response;
@property (nonatomic, readonly) NSData *responseData;
@property (nonatomic, readonly) id responseJSON;
@property (nonatomic, readonly) NSError *error;

+ (instancetype)startWithURLRequest:(NSURLRequest *)urlRequest
                         completion:(SEGAnalyticsRequestCompletionBlock)completion;

@end
