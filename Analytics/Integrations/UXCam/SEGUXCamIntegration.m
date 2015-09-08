//
//  SEGUXCamIntegration.m
//  Analytics
//
//  Created by Richard Groves on 06/07/2015.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import "SEGUXCamIntegration.h"

#import <UXCam/UXCam.h>

#import "SEGAnalytics.h"


@implementation SEGUXCamIntegration

#pragma mark - Initialization

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:@"UXCam"];
    NSLog(@"UXCam load method called");
}

- (id)init
{
    if (self = [super init]) {
        self.name = @"UXCam";
        self.valid = NO;
        self.initialized = NO;
        self.uxcamClass = [UXCam class];
    }
    return self;
}

- (void)start
{
    NSString *apiKey = [self.settings objectForKey:@"apiKey"];
    [self.uxcamClass startWithKey:apiKey];

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
        [self.uxcamClass tagUsersName:userId additionalData:nil]; // Any traits/options we could put into additionalData???
    }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    if (screenTitle.length > 0) {
        [self.uxcamClass tagScreenName:screenTitle];
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    if (event.length > 0) {
        [self.uxcamClass addTag:event]; // Just the basic event - no properties/options added.
    }
}

@end
