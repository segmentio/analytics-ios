#import <Foundation/Foundation.h>
#import "SEGExecutor.h"

@interface SEGSerialExecutor : NSObject<SEGExecutor>

- (instancetype)initWithName:(NSString *)name;

@end
