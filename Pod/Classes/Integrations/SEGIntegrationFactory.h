#import <Foundation/Foundation.h>
#import "SEGIntegration.h"
#import "SEGAnalytics.h"

@class SEGAnalytics;

@protocol SEGIntegrationFactory

-(id<SEGIntegration>) createWithSettings:(NSDictionary *)settings forAnalytics:(SEGAnalytics *)analytics;

-(NSString *)key;

@end
