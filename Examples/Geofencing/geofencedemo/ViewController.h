//
//  ViewController.h
//  geofencedemo
//
//  Created by Kevin McMahon on 9/3/12.
//  Copyright (c) 2012 Kevin McMahon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface ViewController : UIViewController<CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *coordinateLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end
