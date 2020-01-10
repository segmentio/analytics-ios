//
//  SEGHTTPConfiguration.m
//  Analytics
//
//  Created by Lachlan Anderson on 10/1/20.
//  Copyright © 2020 Segment. All rights reserved.
//

#import "SEGHTTPConfiguration.h"

#define DEFAULT_API_BASE [NSURL URLWithString:@"https://api.segment.io/v1"]
#define DEFAULT_CDN_BASE [NSURL URLWithString:@"https://cdn-settings.segment.com/v1"]
#define DEFAULT_MOBILE_SERVICE_BASE [NSURL URLWithString:@"https://mobile-service.segment.com/v1"]

@implementation SEGHTTPConfiguration

+ (SEGHTTPConfiguration *)defaults
{
    return [[SEGHTTPConfiguration alloc] initWithAPIBaseURL:DEFAULT_API_BASE
                                                 cdnBaseURL:DEFAULT_CDN_BASE mobileServiceBaseURL:DEFAULT_MOBILE_SERVICE_BASE];
}


- (instancetype)initWithAPIBaseURL:(NSURL *)apiBaseURL
                        cdnBaseURL:(NSURL *)cdnBaseURL
              mobileServiceBaseURL:(NSURL *)mobileServiceBaseURL
{
    if ((self = [super init])) {
        _apiBaseURL = apiBaseURL ?: DEFAULT_API_BASE;
        _cdnBaseURL = cdnBaseURL ?: DEFAULT_CDN_BASE;
        _mobileServiceBaseURL = mobileServiceBaseURL ?: DEFAULT_MOBILE_SERVICE_BASE;
    }
    return self;
}

@end
