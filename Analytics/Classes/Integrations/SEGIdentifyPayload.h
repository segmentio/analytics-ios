#import <Foundation/Foundation.h>
#import "SEGPayload.h"

NS_ASSUME_NONNULL_BEGIN


@interface SEGIdentifyPayloadBuilder : SEGPayloadBuilder

@property (nonatomic, copy, nullable) NSString *userId;

@property (nonatomic, copy, nullable) NSString *anonymousId;

@property (nonatomic, copy, nullable) JSON_DICT traits;

- (instancetype)init;

@end


@interface SEGIdentifyPayload : SEGPayload

@property (nonatomic, readonly, nullable) NSString *userId;

@property (nonatomic, readonly, nullable) NSString *anonymousId;

@property (nonatomic, readonly, nullable) JSON_DICT traits;

- (instancetype)initWithUserId:(NSString *)userId
                   anonymousId:(NSString *_Nullable)anonymousId
                        traits:(JSON_DICT _Nullable)traits
                       context:(JSON_DICT)context
                  integrations:(JSON_DICT)integrations;

- (instancetype)initWithBuilder:(SEGIdentifyPayloadBuilder *)builder;

@end

NS_ASSUME_NONNULL_END
