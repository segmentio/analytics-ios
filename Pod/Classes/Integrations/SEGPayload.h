#import <Foundation/Foundation.h>

@interface SEGPayload : NSObject

@property (nonatomic,readonly) NSDictionary* context;

- (instancetype)initWithContext:(NSDictionary *)context;

@end
