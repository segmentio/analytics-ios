#import <Foundation/Foundation.h>


@interface SEGLocation : NSObject

@property (nonatomic, copy, readonly) NSString *city;
@property (nonatomic, copy, readonly) NSString *country;
@property (nonatomic, copy, readonly) NSString *postalCode;
@property (nonatomic, copy, readonly) NSString *state;
@property (nonatomic, copy, readonly) NSString *street;
@property (nonatomic, strong, readonly) NSNumber *longitude;
@property (nonatomic, strong, readonly) NSNumber *latitude;
@property (nonatomic, strong, readonly) NSNumber *speed;
@property (nonatomic, copy, readonly) NSDictionary *locationDictionary;
@property (nonatomic, copy, readonly) NSDictionary *addressDictionary;
@property (nonatomic, assign, readonly) BOOL hasKnownLocation;

- (void)startUpdatingLocation;

@end