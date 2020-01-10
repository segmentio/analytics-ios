//
//  SEGHTTPConfiguration.h
//  Analytics
//
//  Created by Lachlan Anderson on 10/1/20.
//  Copyright © 2020 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SEGHTTPConfiguration : NSObject

/// The segment API base URL
@property (nonatomic, strong, nonnull) NSURL *apiBaseURL;

/// The segment CDN base URL
@property (nonatomic, strong, nonnull) NSURL *cdnBaseURL;

/// The mobile service base URL
@property (nonatomic, strong, nonnull) NSURL *mobileServiceBaseURL;


/// Will initialise SEGHTTPConfiguration with the default values
+ (SEGHTTPConfiguration * __nonnull)defaults;

/// Will initialise SEGHTTPConfiguration with the specified values
/// @param apiBaseURL The segment API base URL
/// @param cdnBaseURL The CDN base URl
/// @param mobileServiceBaseURL The mobile service base URL
- (instancetype __nonnull)initWithAPIBaseURL:(NSURL * __nullable)apiBaseURL
                                  cdnBaseURL:(NSURL * __nullable)cdnBaseURL
                        mobileServiceBaseURL:(NSURL * __nullable)mobileServiceBaseURL;

@end

NS_ASSUME_NONNULL_END
