#import "SEGScreenPayload.h"


@implementation SEGScreenPayload

- (instancetype)initWithName:(NSString *)name
                    category:(NSString *)category
                  properties:(NSDictionary *)properties
                     context:(NSDictionary *)context
                integrations:(NSDictionary *)integrations
{
    if (self = [super initWithContext:context integrations:integrations]) {
        _name = [name copy];
        _category = [category copy];
        _properties = [properties copy];
    }
    return self;
}

@end
