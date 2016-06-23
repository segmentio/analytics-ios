#import "SEGLocation.h"
#import "SEGAnalyticsUtils.h"
#import <CoreLocation/CoreLocation.h>

#define LOCATION_STRING_PROPERTY(NAME, PLACEMARK_PROPERTY)     \
-(NSString *)NAME                                          \
{                                                          \
__block NSString *result = nil;                        \
dispatch_sync(self.syncQueue, ^{                       \
result = self.currentPlacemark.PLACEMARK_PROPERTY; \
});                                                    \
return result;                                         \
}

#define LOCATION_NUMBER_PROPERTY(NAME, PLACEMARK_PROPERTY)        \
-(NSNumber *)NAME                                             \
{                                                             \
__block NSNumber *result = nil;                           \
dispatch_sync(self.syncQueue, ^{                          \
result = @(self.currentPlacemark.PLACEMARK_PROPERTY); \
});                                                       \
return result;                                            \
}

#define LOCATION_AGE 300.0 // 5 minutes


@interface SEGLocation () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLPlacemark *currentPlacemark;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) dispatch_queue_t syncQueue;

@end


@implementation SEGLocation

- (id)init
{
    if (![CLLocationManager locationServicesEnabled]) return nil;
    
    if (self = [super init]) {
        self.geocoder = [[CLGeocoder alloc] init];
        self.syncQueue = dispatch_queue_create("io.segment.location.syncQueue", NULL);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
            [self.locationManager startUpdatingLocation];
        });
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

- (void)startUpdatingLocation
{
    if (self.locationManager && self.currentPlacemark) {
        CLLocation *location = self.currentPlacemark.location;
        NSDate *eventDate = location.timestamp;
        NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
        if (fabs(howRecent) > LOCATION_AGE) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.locationManager startUpdatingLocation];
            });
        }
    }
}

- (BOOL)hasKnownLocation
{
    __block BOOL result = NO;
    dispatch_sync(self.syncQueue, ^{
        result = self.currentPlacemark != nil;
    });
    return result;
}

- (NSDictionary *)locationDictionary
{
    return [self dictionaryWithValuesForKeys:@[ @"city", @"country", @"latitude", @"longitude", @"speed" ]];
}

- (NSDictionary *)addressDictionary
{
    return [self dictionaryWithValuesForKeys:@[ @"city", @"country", @"postalCode", @"state", @"street" ]];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (!locations.count) return;
    
    //https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html
    CLLocation *location = [locations lastObject];
    NSDate *eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (fabs(howRecent) < LOCATION_AGE) {
        // If the event is recent, do something with it.
        __weak typeof(self) weakSelf = self;
        [self.geocoder reverseGeocodeLocation:location
                            completionHandler:^(NSArray *placemarks, NSError *error) {
                                if (error) {
                                    SEGLog(@"error: %@", error);
                                } else if (placemarks.count) {
                                    __strong typeof(weakSelf) strongSelf = weakSelf;
                                    dispatch_sync(strongSelf.syncQueue, ^{
                                        strongSelf.currentPlacemark = placemarks.firstObject;
                                        [strongSelf.locationManager stopUpdatingLocation];
                                    });
                                }
                            }];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    SEGLog(@"error: %@", error);
}

@end