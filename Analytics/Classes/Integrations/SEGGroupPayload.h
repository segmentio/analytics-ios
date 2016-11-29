#import <Foundation/Foundation.h>
#import "SEGPayload.h"

NS_ASSUME_NONNULL_BEGIN

@interface SEGGroupPayload : SEGPayload

@property (nonatomic, readonly) NSString *groupId;

@property (nonatomic, readonly, nullable) NSDictionary *traits;

- (instancetype)initWithGroupId:(NSString *)groupId
                         traits:(NSDictionary * _Nullable)traits
                        context:(NSDictionary *)context
                   integrations:(NSDictionary *)integrations;

@end

NS_ASSUME_NONNULL_END
