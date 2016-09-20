#import <Foundation/Foundation.h>


@interface SEGPayload : NSObject

@property (nonatomic, readonly) NSDictionary *context;
@property (nonatomic, readonly) NSDictionary *integrations;

- (instancetype)initWithContext:(NSDictionary *)context integrations:(NSDictionary *)integrations;

@end

@interface SEGApplicationLifecyclePayload : SEGPayload

@property (nonatomic, readonly) NSString *notificationName;

// ApplicationDidFinishLaunching only
@property (nonatomic, readonly) NSDictionary *launchOptions;

@end

@interface SEGRemoteNotificationPayload : SEGPayload

// SEGEventTypeHandleActionWithForRemoteNotification
@property (nonatomic, readonly) NSString *actionIdentifier;

// SEGEventTypeHandleActionWithForRemoteNotification
// SEGEventTypeReceivedRemoteNotification
@property (nonatomic, readonly) NSDictionary *userInfo;

// SEGEventTypeFailedToRegisterForRemoteNotifications
@property (nonatomic, readonly) NSError *error;

// SEGEventTypeRegisteredForRemoteNotifications
@property (nonatomic, readonly) NSData *deviceToken;

@end

@interface SEGContinueUserActivityPayload : SEGPayload

@property (nonatomic, readonly) NSUserActivity *activity;

@end

@interface SEGOpenURLPayload : SEGPayload

@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) NSDictionary *options;

@end

