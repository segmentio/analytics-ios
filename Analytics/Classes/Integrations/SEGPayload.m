#import "SEGPayload.h"


@implementation SEGPayloadBuilder

- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}

@end


@implementation SEGPayload

- (instancetype)initWithContext:(NSDictionary *)context integrations:(NSDictionary *)integrations
{
    if (self = [super init]) {
        _context = [context copy];
        _integrations = [integrations copy];
    }
    return self;
}

- (instancetype)initWithBuilder:(SEGPayloadBuilder *)builder;
{
    if (self = [super init]) {
        _context = [builder.context copy];
        _integrations = [builder.integrations copy];
    }
    return self;
}

@end


@implementation SEGApplicationLifecyclePayload

@end


@implementation SEGRemoteNotificationPayload

@end


@implementation SEGContinueUserActivityPayload

@end


@implementation SEGOpenURLPayload

@end
