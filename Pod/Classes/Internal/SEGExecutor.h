#import <Foundation/Foundation.h>

@protocol SEGExecutor

-(void) submit:(dispatch_block_t) task;

@end
