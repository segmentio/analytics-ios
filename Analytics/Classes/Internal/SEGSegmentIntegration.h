#import <Foundation/Foundation.h>
#import "SEGIntegration.h"
#import "SEGHTTPClient.h"
#import "SEGStorage.h"

extern NSString *const SEGSegmentDidSendRequestNotification;
extern NSString *const SEGSegmentRequestDidSucceedNotification;
extern NSString *const SEGSegmentRequestDidFailNotification;


@interface SEGSegmentIntegration : NSObject <SEGIntegration>

- (id)initWithAnalytics:(SEGAnalytics *)analytics httpClient:(SEGHTTPClient *)httpClient storage:(id<SEGStorage>)storage;

@end
