#import "SEGAnalytics.h"

@interface SEGAnalyticsConfiguration ()

@property (nonatomic, copy, readwrite) NSString *writeKey;

@property (nonatomic, readwrite) NSMutableArray *factories;

@end

@implementation SEGAnalyticsConfiguration

+ (instancetype)configurationWithWriteKey:(NSString *)writeKey
{
    return [[self alloc] initWithWriteKey:writeKey];
}

- (id)initWithWriteKey:(NSString *)writeKey
{
    if (self = [self init]) {
        self.writeKey = writeKey;
        self.shouldUseLocationServices = NO;
        self.enableAdvertisingTracking = YES;
        self.flushAt = 20;
        self.factories = [NSMutableArray array];
    }
    return self;
}

-(void)use:(id<SEGIntegrationFactory>)factory{
    [_factories addObject:factory];
}

@end

@implementation SEGAnalytics

@end
