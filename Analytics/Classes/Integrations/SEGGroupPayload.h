#import <Foundation/Foundation.h>
#import "SEGPayload.h"

NS_ASSUME_NONNULL_BEGIN


@interface SEGGroupPayloadBuilder : SEGPayloadBuilder

@property (nonatomic, copy, nullable) NSString *groupId;

@property (nonatomic, copy, nullable) JSON_DICT traits;

- (instancetype)init;

@end


@interface SEGGroupPayload : SEGPayload

@property (nonatomic, readonly) NSString *groupId;

@property (nonatomic, readonly, nullable) JSON_DICT traits;

- (instancetype)initWithGroupId:(NSString *)groupId
                         traits:(JSON_DICT _Nullable)traits
                        context:(JSON_DICT)context
                   integrations:(JSON_DICT)integrations;

- (instancetype)initWithBuilder:(SEGGroupPayloadBuilder *)builder;

@end

NS_ASSUME_NONNULL_END
