#import <Foundation/Foundation.h>
#import "SEGPayload.h"

NS_ASSUME_NONNULL_BEGIN

@interface SEGIdentifyPayload : SEGPayload

@property (nonatomic, readonly) NSString *userId;

@property (nonatomic, readonly, nullable) NSString *anonymousId;

@property (nonatomic, readonly, nullable) NSDictionary *traits;

- (instancetype)initWithUserId:(NSString *)userId
                   anonymousId:(NSString * _Nullable)anonymousId
                        traits:(NSDictionary * _Nullable)traits
                       context:(NSDictionary *)context
                  integrations:(NSDictionary *)integrations;

@end

NS_ASSUME_NONNULL_END
