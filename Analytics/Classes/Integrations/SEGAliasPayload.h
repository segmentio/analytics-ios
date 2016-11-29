#import <Foundation/Foundation.h>
#import "SEGPayload.h"

NS_ASSUME_NONNULL_BEGIN

@interface SEGAliasPayload : SEGPayload

@property (nonatomic, readonly) NSString *theNewId;

- (instancetype)initWithNewId:(NSString *)newId
                      context:(NSDictionary *)context
                 integrations:(NSDictionary *)integrations;

@end

NS_ASSUME_NONNULL_END
