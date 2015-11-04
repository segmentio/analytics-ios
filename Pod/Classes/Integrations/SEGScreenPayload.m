#import "SEGScreenPayload.h"

@implementation SEGScreenPayload

- (instancetype)initWithName:(NSString *)name
                   properties:(NSDictionary *)properties
                      context:(NSDictionary *)context
{
    if (self = [super initWithContext:context]) {
        _name = [name copy];
        _properties = [properties copy];
    }
    return self;
}

@end
