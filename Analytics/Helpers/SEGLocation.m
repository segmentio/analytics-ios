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

#define LOCATION_STRING_PROPERTY(NAME, PLACEMARK_PROPERTY) \
- (NSString *)NAME { \
  __block NSString *result = nil; \
  dispatch_sync(self.syncQueue, ^{ \
    result = self.currentPlacemark.PLACEMARK_PROPERTY; \
  }); \
  return result; \
}

#define LOCATION_NUMBER_PROPERTY(NAME, PLACEMARK_PROPERTY) \
- (NSNumber *)NAME { \
  __block NSNumber *result = nil; \
  dispatch_sync(self.syncQueue, ^{ \
    result = @(self.currentPlacemark.PLACEMARK_PROPERTY); \
  }); \
  return result; \
}

@interface SEGLocation () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLPlacemark *currentPlacemark;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) dispatch_queue_t syncQueue;

@end

@implementation SEGLocation

- (id)init {
  if (![CLLocationManager locationServicesEnabled]) return nil;
  
  if (self = [super init]) {
    self.geocoder = [[CLGeocoder alloc] init];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    self.syncQueue = dispatch_queue_create("io.segment.location.syncQueue", NULL);
  }
  return self;
}

LOCATION_STRING_PROPERTY(state, administrativeArea);
LOCATION_STRING_PROPERTY(country, country);
LOCATION_STRING_PROPERTY(city, locality);
LOCATION_STRING_PROPERTY(postalCode, postalCode);
LOCATION_STRING_PROPERTY(street, thoroughfare);
LOCATION_NUMBER_PROPERTY(latitude, location.coordinate.latitude);
LOCATION_NUMBER_PROPERTY(longitude, location.coordinate.longitude);
LOCATION_NUMBER_PROPERTY(speed, location.speed);

- (BOOL)hasKnownLocation {
  __block BOOL result = NO;
  dispatch_sync(self.syncQueue, ^{ result = self.currentPlacemark != nil; });
  return result;
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
    dispatch_sync(strongSelf.syncQueue, ^{
      strongSelf.currentPlacemark = placemarks.firstObject;
    });
  }];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
  SEGLog(@"error: %@", error);
}

@end
