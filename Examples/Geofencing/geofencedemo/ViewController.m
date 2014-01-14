//
//  ViewController.m
//  geofencedemo
//
//  Created by Kevin McMahon on 9/3/12.
//  Copyright (c) 2012 Kevin McMahon. All rights reserved.
//

#import "ViewController.h"
#import "Analytics/Analytics.h"
#import <CoreLocation/CoreLocation.h>

@implementation ViewController
@synthesize coordinateLabel;
@synthesize mapView;

CLLocationManager *_locationManager;
NSArray *_regionArray;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initializeMap];
    [self initializeLocationManager];
    NSArray *geofences = [self buildGeofenceData];
    [self initializeRegionMonitoring:geofences];
    [self initializeLocationUpdates];
}

- (void)viewDidUnload
{
    [self setCoordinateLabel:nil];
    [self setMapView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)initializeMap {
    CLLocationCoordinate2D initialCoordinate;
    initialCoordinate.latitude = 41.88072;
    initialCoordinate.longitude = -87.67429;

    [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(initialCoordinate, 400, 400) animated:YES];
    self.mapView.centerCoordinate = initialCoordinate;
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}

- (void)initializeLocationManager {
    // Check to ensure location services are enabled
    if(![CLLocationManager locationServicesEnabled]) {
        [self showAlertWithMessage:@"You need to enable location services to use this app."];
        return;
    }
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
}


- (void) initializeRegionMonitoring:(NSArray*)geofences {
    
    if (_locationManager == nil) {
        [NSException raise:@"Location Manager Not Initialized" format:@"You must initialize location manager first."];
    }
    
    if(![CLLocationManager regionMonitoringAvailable]) {
        [self showAlertWithMessage:@"This app requires region monitoring features which are unavailable on this device."];
        return;
    }
    
    for(CLRegion *geofence in geofences) {
        [_locationManager startMonitoringForRegion:geofence];
    }

}

- (NSArray*) buildGeofenceData {
    NSString* plistPath = [[NSBundle mainBundle] pathForResource:@"regions" ofType:@"plist"];
    _regionArray = [NSArray arrayWithContentsOfFile:plistPath];
    
    NSMutableArray *geofences = [NSMutableArray array];
    for(NSDictionary *regionDict in _regionArray) {
        CLRegion *region = [self mapDictionaryToRegion:regionDict];
        [geofences addObject:region];
    }
    
    return [NSArray arrayWithArray:geofences];
}

- (CLRegion*)mapDictionaryToRegion:(NSDictionary*)dictionary {
    NSString *title = [dictionary valueForKey:@"title"];
    
    CLLocationDegrees latitude = [[dictionary valueForKey:@"latitude"] doubleValue];
    CLLocationDegrees longitude =[[dictionary valueForKey:@"longitude"] doubleValue];
    CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
        
    CLLocationDistance regionRadius = [[dictionary valueForKey:@"radius"] doubleValue];
    
    return [[CLRegion alloc] initCircularRegionWithCenter:centerCoordinate
                                                   radius:regionRadius
                                               identifier:title];
}

- (void)initializeLocationUpdates {
    [_locationManager startUpdatingLocation];
}

- (NSString *)applicationState {
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateActive) {
        return @"Active";
    } else if (state == UIApplicationStateBackground) {
        return @"Background";
    } else if (state == UIApplicationStateInactive) {
        return @"Inactive";
    } else {
        return @"Unknown";
    }
}

#pragma mark - Location Manager - Region Task Methods

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSString *appState = [self applicationState];
    NSLog(@"Entered Region - %@ (active? %@)", region.identifier, appState);
    [[Analytics sharedAnalytics] track:@"Entered Region"
                            properties:@{ @"region" : region.identifier, @"state" : appState }];
    [self showRegionAlert:@"Entering Region" forRegion:region.identifier];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSString *appState = [self applicationState];
    NSLog(@"Exited Region - %@ (active? %@)", region.identifier, appState);
    [[Analytics sharedAnalytics] track:@"Exited Region"
                            properties:@{ @"region" : region.identifier, @"state" : appState }];
    [self showRegionAlert:@"Exiting Region" forRegion:region.identifier];
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"Started monitoring %@ region", region.identifier);
}

#pragma mark - Location Manager - Standard Task Methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    self.coordinateLabel.text = [NSString stringWithFormat:@"%f,%f",newLocation.coordinate.latitude, newLocation.coordinate.longitude];
}
#pragma mark - Alert Methods

- (void) showRegionAlert:(NSString *)alertText forRegion:(NSString *)regionIdentifier {
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:alertText
                                                      message:regionIdentifier
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    [message show];
}

- (void)showAlertWithMessage:(NSString*)alertText {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Location Services Error"
                                                        message:alertText
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
}

@end