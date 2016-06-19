#import <Foundation/Foundation.h>
#import "SEGPayload.h"


@interface SEGGroupPayload : SEGPayload

@property (nonatomic, readonly) NSString *groupId;

@property (nonatomic, readonly) NSDictionary *traits;

- (instancetype)initWithGroupId:(NSString *)groupId
                         traits:(NSDictionary *)traits
                        context:(NSDictionary *)context
                   integrations:(NSDictionary *)integrations;

@end