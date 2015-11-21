#import "SEGIdentifyPayload.h"


@implementation SEGIdentifyPayload

- (instancetype)initWithUserId:(NSString *)userId
                        traits:(NSDictionary *)traits
                       context:(NSDictionary *)context
                  integrations:(NSDictionary *)integrations
{
    if (self = [super initWithContext:context integrations:integrations]) {
        _userId = [userId copy];
        _traits = [traits copy];
    }
    return self;
}

@end
