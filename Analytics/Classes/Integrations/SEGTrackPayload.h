#import <Foundation/Foundation.h>
#import "SEGPayload.h"

NS_ASSUME_NONNULL_BEGIN


@interface SEGTrackPayloadBuilder : SEGPayloadBuilder

@property (nonatomic, copy) NSString *event;

@property (nonatomic, copy, nullable) JSON_DICT properties;

- (instancetype)init;

@end


@interface SEGTrackPayload : SEGPayload

@property (nonatomic, readonly) NSString *event;

@property (nonatomic, readonly, nullable) JSON_DICT properties;

- (instancetype)initWithEvent:(NSString *)event
                   properties:(JSON_DICT _Nullable)properties
                      context:(JSON_DICT)context
                 integrations:(JSON_DICT)integrations;

- (instancetype)initWithBuilder:(SEGTrackPayloadBuilder *)builder;

@end


NS_ASSUME_NONNULL_END
