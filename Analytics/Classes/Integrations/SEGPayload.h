#import <Foundation/Foundation.h>


@interface SEGPayload : NSObject

@property (nonatomic, readonly) NSDictionary *context;
@property (nonatomic, readonly) NSDictionary *integrations;

- (instancetype)initWithContext:(NSDictionary *)context integrations:(NSDictionary *)integrations;

@end

@interface SEGApplicationLifecyclePayload : SEGPayload

@property (nonatomic, strong) NSString *notificationName;

// ApplicationDidFinishLaunching only
@property (nonatomic, strong) NSDictionary *launchOptions;

@end

@interface SEGRemoteNotificationPayload : SEGPayload

// SEGEventTypeHandleActionWithForRemoteNotification
@property (nonatomic, strong) NSString *actionIdentifier;

// SEGEventTypeHandleActionWithForRemoteNotification
// SEGEventTypeReceivedRemoteNotification
@property (nonatomic, strong) NSDictionary *userInfo;

// SEGEventTypeFailedToRegisterForRemoteNotifications
@property (nonatomic, strong) NSError *error;

// SEGEventTypeRegisteredForRemoteNotifications
@property (nonatomic, strong) NSData *deviceToken;

@end

@interface SEGContinueUserActivityPayload : SEGPayload

@property (nonatomic, strong) NSUserActivity *activity;

@end

@interface SEGOpenURLPayload : SEGPayload

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSDictionary *options;

@end

