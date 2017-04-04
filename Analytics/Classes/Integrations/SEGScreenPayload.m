#import "SEGScreenPayload.h"


@implementation SEGScreenPayloadBuilder

- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}

@end


@implementation SEGScreenPayload

- (instancetype)initWithName:(NSString *)name
                  properties:(JSON_DICT)properties
                     context:(JSON_DICT)context
                integrations:(JSON_DICT)integrations
{
    if (self = [super initWithContext:context integrations:integrations]) {
        _name = [name copy];
        _properties = [properties copy];
    }
    return self;
}

- (instancetype)initWithBuilder:(SEGScreenPayloadBuilder *)builder
{
    if (self = [super initWithBuilder:builder]) {
        NSParameterAssert(builder);

        NSString *name = [builder.name copy];
        NSCAssert1(name.length > 0, @"name (%@) must not be null or empty.", name);
        _name = name;

        _properties = [builder.properties copy];
    }

    return self;
}

@end
