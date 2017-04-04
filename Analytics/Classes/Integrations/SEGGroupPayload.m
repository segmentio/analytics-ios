#import "SEGGroupPayload.h"


@implementation SEGGroupPayloadBuilder

- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}

@end


@implementation SEGGroupPayload

- (instancetype)initWithGroupId:(NSString *)groupId
                         traits:(NSDictionary *)traits
                        context:(NSDictionary *)context
                   integrations:(NSDictionary *)integrations
{
    if (self = [super initWithContext:context integrations:integrations]) {
        _groupId = [groupId copy];
        _traits = [traits copy];
    }
    return self;
}

- (instancetype)initWithBuilder:(SEGGroupPayloadBuilder *)builder
{
    if (self = [super initWithBuilder:builder]) {
        NSParameterAssert(builder);

        NSString *groupId = [builder.groupId copy];
        NSCAssert1(groupId.length > 0, @"groupId (%@) must not be null or empty.", groupId);
        _groupId = groupId;

        _traits = [builder.traits copy];
    }

    return self;
}

@end
