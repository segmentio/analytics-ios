//
//  SEGUXcamIntegration.m
//  Analytics
//
//  Created by Richard Groves on 01/06/2015.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import "SEGUXCamIntegration.h"

#include <UXCam/UXCam.h>

#import "SEGAnalytics.h"


@implementation SEGUXCamIntegration

#pragma mark - Initialization

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:@"UXCam"];
}

- (id)init
{
    if (self = [super init]) {
        self.name = @"UXCam";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    NSString *apiKey = [self.settings objectForKey:@"apiKey"];
    [UXCam startWithKey:apiKey];

    [super start];
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasAPIKey = [self.settings objectForKey:@"apiKey"] != nil;
    self.valid = hasAPIKey;
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    if (userId.length > 0) {
        [UXCam tagUsersName:userId additionalData:nil]; // Any traits/options we could put into additionalData???
    }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    if (screenTitle.length > 0) {
        [UXCam tagScreenName:screenTitle];
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    if (event.length > 0) {
        [UXCam addTag:event]; // Just the basic event - no properties/options added.
    }
}

@end
