// TapstreamProvider.h

#import <Foundation/Foundation.h>
#import "Provider.h"


@interface TapstreamProvider : Provider

@property(nonatomic, strong) NSString *name;
@property(nonatomic, assign) BOOL valid;
@property(nonatomic, assign) BOOL initialized;
@property(nonatomic, strong) NSDictionary *settings;

+ (instancetype)withNothing;
- (id)initWithNothing;

@end
