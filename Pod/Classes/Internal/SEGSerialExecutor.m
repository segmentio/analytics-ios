#import "SEGSerialExecutor.h"

@interface SEGSerialExecutor()

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@end

@implementation SEGSerialExecutor

- (instancetype)initWithName:(NSString *)name
{
    if (self = [super init]) {
        const char *label = [name cStringUsingEncoding:NSASCIIStringEncoding];
        _serialQueue = dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

-(void) submit:(dispatch_block_t) task
{
    dispatch_async(self.serialQueue, task);
}

@end
