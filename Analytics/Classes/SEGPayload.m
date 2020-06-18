#import "SEGPayload.h"
#import "SEGState.h"

@implementation SEGPayload

- (instancetype)initWithContext:(NSDictionary *)context integrations:(NSDictionary *)integrations
{
    if (self = [super init]) {
        // combine existing state with user supplied context.
        NSDictionary *internalContext = [SEGState sharedInstance].context.payload;
        
        NSMutableDictionary *combinedContext = [[NSMutableDictionary alloc] init];
        [combinedContext addEntriesFromDictionary:internalContext];
        [combinedContext addEntriesFromDictionary:context];

        _context = [combinedContext copy];
        _integrations = [integrations copy];
    }
    return self;
}

@end


@implementation SEGApplicationLifecyclePayload

@end


@implementation SEGRemoteNotificationPayload

@end


@implementation SEGContinueUserActivityPayload

@end


@implementation SEGOpenURLPayload

@end
