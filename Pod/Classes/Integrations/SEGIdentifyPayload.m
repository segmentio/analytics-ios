#import "SEGIdentifyPayload.h"

@implementation SEGIdentifyPayload

- (instancetype)initWithUserId:(NSString *)userId
                   traits:(NSDictionary *)traits
                      context:(NSDictionary *)context
{
    if (self = [super initWithContext:context]) {
        _userId = [userId copy];
        _traits = [_traits copy];
    }
    return self;
}

@end
