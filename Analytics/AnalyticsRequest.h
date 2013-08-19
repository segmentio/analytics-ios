//
//  AnalyticsRequest.h
//  Analytics
//
//  Created by Tony Xiao on 8/19/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AnalyticsRequest;
@protocol AnalyticsRequestDelegate <NSObject>

- (void)requestDidComplete:(AnalyticsRequest *)request;

@end

@interface AnalyticsRequest : NSObject

@property (nonatomic, weak) id<AnalyticsRequestDelegate> delegate;

@property (nonatomic, readonly) NSURLRequest *urlRequest;
@property (nonatomic, readonly) NSHTTPURLResponse *response;
@property (nonatomic, readonly) NSMutableData *responseData;
@property (nonatomic, readonly) id responseJSON;
@property (nonatomic, readonly) NSError *error;

+ (instancetype)startRequestWithURLRequest:(NSURLRequest *)urlRequest
                                  delegate:(id<AnalyticsRequestDelegate>)delegate;

@end
