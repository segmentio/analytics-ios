#import "SEGPayload.h"

@implementation SEGPayload

- (instancetype)initWithContext:(NSDictionary *)context
{
    if (self = [super init]) {
        _context = [context copy];
    }
    return self;
}

@end
