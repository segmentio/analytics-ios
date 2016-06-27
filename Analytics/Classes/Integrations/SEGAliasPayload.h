#import <Foundation/Foundation.h>
#import "SEGPayload.h"


@interface SEGAliasPayload : SEGPayload

@property (nonatomic, readonly) NSString *theNewId;

- (instancetype)initWithNewId:(NSString *)newId
                      context:(NSDictionary *)context
                 integrations:(NSDictionary *)integrations;

@end
