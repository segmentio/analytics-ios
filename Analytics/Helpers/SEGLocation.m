//
//  SIOLocation.m
//  Analytics
//
//  Created by Travis Jeffery on 4/25/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import "SEGLocation.h"
#import "SEGAnalyticsUtils.h"

#import <CoreLocation/CoreLocation.h>

@interface SEGLocation () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLPlacemark *currentPlacemark;
@property (nonatomic, strong) CLGeocoder *geocoder;

@end

@implementation SEGLocation

- (id)init {
  if (![CLLocationManager locationServicesEnabled]) return nil;
  
  if (self = [super init]) {
    self.geocoder = [[CLGeocoder alloc] init];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
  }
  return self;
}

- (NSString *)state {
  return self.currentPlacemark.administrativeArea;
}

- (NSString *)country {
  return self.currentPlacemark.country;
}

- (NSString *)city {
  return self.currentPlacemark.locality;
}

- (NSString *)postalCode {
  return self.currentPlacemark.postalCode;
}

- (NSString *)street {
  return self.currentPlacemark.thoroughfare;
}

- (BOOL)hasKnownLocation {
  return self.currentPlacemark != nil;
}

- (NSNumber *)latitude {
  return @(self.currentPlacemark.location.coordinate.latitude);
}

- (NSNumber *)longitude {
  return @(self.currentPlacemark.location.coordinate.longitude);
}

- (NSNumber *)speed {
  return @(self.currentPlacemark.location.speed);
}

- (NSDictionary *)locationDictionary {
  return [self dictionaryWithValuesForKeys:@[ @"city", @"country", @"latitude", @"longitude", @"speed" ]];
}

- (NSDictionary *)addressDictionary {
  return [self dictionaryWithValuesForKeys:@[ @"city", @"country", @"postalCode", @"state", @"street" ]];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
  if (!locations.count) return;
  
  __weak typeof(self) weakSelf = self;
  [self.geocoder reverseGeocodeLocation:locations.firstObject completionHandler:^(NSArray *placemarks, NSError *error) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    strongSelf.currentPlacemark = placemarks.firstObject;
  }];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
  SEGLog(@"error: %@", error);
}

@end
