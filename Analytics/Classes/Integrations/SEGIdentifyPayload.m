#import "SEGIdentifyPayload.h"


@implementation SEGIdentifyPayloadBuilder

- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}

@end


@implementation SEGIdentifyPayload

- (instancetype)initWithUserId:(NSString *)userId
                   anonymousId:(NSString *)anonymousId
                        traits:(JSON_DICT)traits
                       context:(JSON_DICT)context
                  integrations:(JSON_DICT)integrations
{
    if (self = [super initWithContext:context integrations:integrations]) {
        _userId = [userId copy];
        _anonymousId = [anonymousId copy];
        _traits = [traits copy];
    }
    return self;
}

- (instancetype)initWithBuilder:(SEGIdentifyPayloadBuilder *)builder
{
    if (self = [super initWithBuilder:builder]) {
        NSParameterAssert(builder);

        NSString *userId = [builder.userId copy];
        NSString *anonymousId = [builder.anonymousId copy];
        JSON_DICT traits = [builder.traits copy];

        NSCAssert3(userId.length > 0 || anonymousId.length > 0 || traits.count > 0, @"either userId (%@), anonymousId (%@) or traits (%@) must be provided.", userId, anonymousId, traits);

        _userId = userId;
        _anonymousId = anonymousId;
        _traits = traits;
    }

    return self;
}

@end
