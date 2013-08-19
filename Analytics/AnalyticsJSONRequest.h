//
//  AnalyticsJSONRequest.h
//  Analytics
//
//  Created by Tony Xiao on 8/19/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AnalyticsJSONRequest;
@protocol AnalyticsJSONRequestDelegate <NSObject>

- (void)requestDidComplete:(AnalyticsJSONRequest *)request;

@end

@interface AnalyticsJSONRequest : NSObject

@property (nonatomic, weak) id<AnalyticsJSONRequestDelegate> delegate;

@property (nonatomic, readonly) NSURLRequest *urlRequest;
@property (nonatomic, readonly) NSHTTPURLResponse *response;
@property (nonatomic, readonly) NSMutableData *responseData;
@property (nonatomic, readonly) id responseJSON;
@property (nonatomic, readonly) NSError *error;

+ (instancetype)startRequestWithURLRequest:(NSURLRequest *)urlRequest
                                  delegate:(id<AnalyticsJSONRequestDelegate>)delegate;

@end
