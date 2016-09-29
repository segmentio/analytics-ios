#import "SEGTimerProxy.h"

@interface SEGTimerProxy ()

@property (nonatomic, weak) id targetObject;

@end

@implementation SEGTimerProxy

- (instancetype)initWithTimerTarget:(id)targetObject {
    
    if (self = [super init]) {
        
        self.targetObject = targetObject;
    }
    
    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    
    return [self.targetObject respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    
    if ([self.targetObject respondsToSelector:aSelector]) {
        
        return self.targetObject;
    }
    
    return nil;
}

@end
