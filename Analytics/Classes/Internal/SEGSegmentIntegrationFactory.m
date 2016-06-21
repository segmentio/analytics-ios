#import "SEGSegmentIntegrationFactory.h"
#import "SEGSegmentIntegration.h"


@implementation SEGSegmentIntegrationFactory

+ (id)instance
{
    static dispatch_once_t once;
    static SEGSegmentIntegrationFactory *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    return self;
}

- (id<SEGIntegration>)createWithSettings:(NSDictionary *)settings forAnalytics:(SEGAnalytics *)analytics
{
    return [[SEGSegmentIntegration alloc] initWithAnalytics:analytics];
}

- (NSString *)key
{
    return @"Segment.io";
}

@end