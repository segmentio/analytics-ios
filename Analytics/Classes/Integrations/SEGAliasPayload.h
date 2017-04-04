#import <Foundation/Foundation.h>
#import "SEGPayload.h"

NS_ASSUME_NONNULL_BEGIN


@interface SEGAliasPayloadBuilder : SEGPayloadBuilder

@property (nonatomic, copy, nullable) NSString *theNewId;

- (instancetype)init;

@end


@interface SEGAliasPayload : SEGPayload

@property (nonatomic, readonly) NSString *theNewId;

- (instancetype)initWithNewId:(NSString *)newId
                      context:(JSON_DICT)context
                 integrations:(JSON_DICT)integrations;

- (instancetype)initWithBuilder:(SEGAliasPayloadBuilder *)builder;

@end

NS_ASSUME_NONNULL_END
