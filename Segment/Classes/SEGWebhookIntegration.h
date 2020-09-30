#import "SEGIntegration.h"
#import "SEGIntegrationFactory.h"
#import "SEGHTTPClient.h"

NS_SWIFT_NAME(WebhookIntegrationFactory)
@interface SEGWebhookIntegrationFactory : NSObject <SEGIntegrationFactory>

@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *webhookUrl;

- (instancetype)initWithName:(NSString *)name webhookUrl:(NSString *)webhookUrl;

@end
