#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SEGPayload : NSObject

@property (nonatomic, readonly) NSDictionary *context;
@property (nonatomic, readonly) NSDictionary *integrations;

- (instancetype)initWithContext:(NSDictionary *)context integrations:(NSDictionary *)integrations;

@end


@interface SEGApplicationLifecyclePayload : SEGPayload

@property (nonatomic, strong) NSString *notificationName;

// ApplicationDidFinishLaunching only
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;

@end


@interface SEGContinueUserActivityPayload : SEGPayload

@property (nonatomic, strong) NSUserActivity *activity;

@end


@interface SEGOpenURLPayload : SEGPayload

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSDictionary *options;

@end

NS_ASSUME_NONNULL_END


@interface SEGRemoteNotificationPayload : SEGPayload

// SEGEventTypeHandleActionWithForRemoteNotification
@property (nonatomic, strong, nullable) NSString *actionIdentifier;

// SEGEventTypeHandleActionWithForRemoteNotification
// SEGEventTypeReceivedRemoteNotification
@property (nonatomic, strong, nullable) NSDictionary *userInfo;

// SEGEventTypeFailedToRegisterForRemoteNotifications
@property (nonatomic, strong, nullable) NSError *error;

// SEGEventTypeRegisteredForRemoteNotifications
@property (nonatomic, strong, nullable) NSData *deviceToken;

@end
