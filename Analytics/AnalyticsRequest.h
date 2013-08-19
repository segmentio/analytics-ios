//
//  AnalyticsRequest.h
//  Analytics
//
//  Created by Tony Xiao on 8/19/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^AnalyticsRequestCompletionBlock)(void);

@interface AnalyticsRequest : NSObject

@property (nonatomic, readonly) NSURLRequest *urlRequest;
@property (nonatomic, readonly) NSHTTPURLResponse *response;
@property (nonatomic, readonly) NSMutableData *responseData;
@property (nonatomic, readonly) id responseJSON;
@property (nonatomic, readonly) NSError *error;

+ (instancetype)startWithURLRequest:(NSURLRequest *)urlRequest
                         completion:(AnalyticsRequestCompletionBlock)completion;

@end
