#import <Foundation/Foundation.h>
#import "SEGPayload.h"


@interface SEGIdentifyPayload : SEGPayload

@property (nonatomic, readonly) NSString *userId;

@property (nonatomic, readonly) NSDictionary *traits;

- (instancetype)initWithUserId:(NSString *)userId
                        traits:(NSDictionary *)traits
                       context:(NSDictionary *)context
                  integrations:(NSDictionary *)integrations;

@end
