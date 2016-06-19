#import <Foundation/Foundation.h>
#import "SEGIntegration.h"

extern NSString *const SEGSegmentDidSendRequestNotification;
extern NSString *const SEGSegmentRequestDidSucceedNotification;
extern NSString *const SEGSegmentRequestDidFailNotification;


@interface SEGSegmentIntegration : NSObject <SEGIntegration>

@property (nonatomic, copy) NSString *anonymousId;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, strong) NSURL *apiURL;

- (id)initWithAnalytics:(SEGAnalytics *)analytics;

@end