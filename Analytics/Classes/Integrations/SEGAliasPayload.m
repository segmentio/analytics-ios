#import "SEGAliasPayload.h"


@implementation SEGAliasPayloadBuilder

- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}

@end


@implementation SEGAliasPayload

- (instancetype)initWithNewId:(NSString *)newId
                      context:(NSDictionary *)context
                 integrations:(NSDictionary *)integrations
{
    if (self = [super initWithContext:context integrations:integrations]) {
        _theNewId = [newId copy];
    }
    return self;
}

- (instancetype)initWithBuilder:(SEGAliasPayloadBuilder *)builder
{
    if (self = [super initWithBuilder:builder]) {
        NSParameterAssert(builder);

        NSString *theNewId = [builder.theNewId copy];
        NSCAssert1(theNewId.length > 0, @"newId (%@) must not be null or empty.", theNewId);
        _theNewId = theNewId;
    }

    return self;
}

@end
