//
//  AmplitudeLocationManagerDelegate.m
//  Fawkes
//
//  Created by Spenser Skates on 8/19/12.
//  Copyright (c) 2012 Sonalight, Inc. All rights reserved.
//

#import "AmplitudeLocationManagerDelegate.h"
#import "Amplitude.h"

@implementation AmplitudeLocationManagerDelegate


- (void)locationManager:(CLLocationManager*) manager didFailWithError:(NSError*) error
{
}

- (void)locationManager:(CLLocationManager*) manager didUpdateToLocation:(CLLocation*) newLocation fromLocation:(CLLocation*) oldLocation
{
}

- (void)locationManager:(CLLocationManager*) manager didChangeAuthorizationStatus:(CLAuthorizationStatus) status
{
    if (status == kCLAuthorizationStatusAuthorized) {
        SEL updateLocation = NSSelectorFromString(@"updateLocation");
        [Amplitude performSelector:updateLocation];
    }
}

@end
