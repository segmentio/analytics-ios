#import <Foundation/Foundation.h>
#import "SEGIntegration.h"

extern NSString *const SEGSegmentDidSendRequestNotification;
extern NSString *const SEGSegmentRequestDidSucceedNotification;
extern NSString *const SEGSegmentRequestDidFailNotification;


@interface SEGSegmentIntegration : NSObject <SEGIntegration>

- (id)initWithAnalytics:(SEGAnalytics *)analytics;

@end
