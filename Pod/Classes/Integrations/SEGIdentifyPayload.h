#import <Foundation/Foundation.h>
#import "SEGPayload.h"


@interface SEGIdentifyPayload : SEGPayload

@property (nonatomic, readonly) NSString *userId;

@property (nonatomic, readonly) NSString *anonymousId;

@property (nonatomic, readonly) NSDictionary *traits;

- (instancetype)initWithUserId:(NSString *)userId
                   anonymousId:(NSString *)anonymousId
                        traits:(NSDictionary *)traits
                       context:(NSDictionary *)context
                  integrations:(NSDictionary *)integrations;

@end
