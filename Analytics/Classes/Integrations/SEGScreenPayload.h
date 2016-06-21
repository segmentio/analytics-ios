#import <Foundation/Foundation.h>
#import "SEGPayload.h"


@interface SEGScreenPayload : SEGPayload

@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly) NSString *category;

@property (nonatomic, readonly) NSDictionary *properties;

- (instancetype)initWithName:(NSString *)name
                  properties:(NSDictionary *)properties
                     context:(NSDictionary *)context
                integrations:(NSDictionary *)integrations;

@end