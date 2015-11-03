#import "SEGAliasPayload.h"

@implementation SEGAliasPayload

- (instancetype)initWithNewId:(NSString *)newId
                      context:(NSDictionary *)context
{
    if (self = [super initWithContext:context]) {
        _theNewId = [newId copy];
    }
    return self;
}

@end
