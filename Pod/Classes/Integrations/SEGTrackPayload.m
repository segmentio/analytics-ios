#import "SEGTrackPayload.h"

@implementation SEGTrackPayload


- (instancetype)initWithEvent:(NSString *)event
                   properties:(NSDictionary *)properties
                      context:(NSDictionary *)context
{
    if (self = [super initWithContext:context]) {
        _event = [event copy];
        _properties = [properties copy];
    }
    return self;
}

@end
