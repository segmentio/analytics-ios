#import <Foundation/Foundation.h>
#import "SEGPayload.h"


@interface SEGTrackPayload : SEGPayload

@property (nonatomic, readonly) NSString *event;

@property (nonatomic, readonly) NSDictionary *properties;

- (instancetype)initWithEvent:(NSString *)event
                   properties:(NSDictionary *)properties
                      context:(NSDictionary *)context
                 integrations:(NSDictionary *)integrations;

@end