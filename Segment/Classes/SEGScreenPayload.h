@import Foundation;
#import "SEGPayload.h"

NS_ASSUME_NONNULL_BEGIN


NS_SWIFT_NAME(ScreenPayload)
@interface SEGScreenPayload : SEGPayload

@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly, nullable) NSString *category;

@property (nonatomic, readonly, nullable) NSDictionary *properties;

- (instancetype)initWithName:(NSString *)name
                    category:(NSString *)category
                  properties:(NSDictionary *_Nullable)properties
                     context:(NSDictionary *)context
                integrations:(NSDictionary *)integrations;

@end

NS_ASSUME_NONNULL_END
