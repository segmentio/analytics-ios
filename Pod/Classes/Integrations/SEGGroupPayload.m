#import "SEGGroupPayload.h"

@implementation SEGGroupPayload

- (instancetype)initWithGroupId:(NSString *)groupId
                        traits:(NSDictionary *)traits
                       context:(NSDictionary *)context
{
    if (self = [super initWithContext:context]) {
        _groupId = [groupId copy];
        _traits = [_traits copy];
    }
    return self;
}

@end
