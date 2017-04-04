#import "SEGTrackPayload.h"


@implementation SEGTrackPayloadBuilder

- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}

@end


@implementation SEGTrackPayload

- (instancetype)initWithEvent:(NSString *)event
                   properties:(JSON_DICT)properties
                      context:(JSON_DICT)context
                 integrations:(JSON_DICT)integrations
{
    if (self = [super initWithContext:context integrations:integrations]) {
        _event = [event copy];
        _properties = [properties copy];
    }
    return self;
}

- (instancetype)initWithBuilder:(SEGTrackPayloadBuilder *)builder
{
    if (self = [super initWithBuilder:builder]) {
        NSParameterAssert(builder);

        NSString *event = [builder.event copy];
        NSCAssert1(event.length > 0, @"event (%@) must not be null or empty.", event);
        _event = event;

        _properties = [builder.properties copy];
    }

    return self;
}

@end
