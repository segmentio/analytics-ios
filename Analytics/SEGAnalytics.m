// Analytics.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <UIKit/UIKit.h>
#import "SEGAnalyticsUtils.h"
#import "SEGAnalyticsIntegration.h"
#import "SEGAnalyticsRequest.h"
#import "SEGAnalytics.h"

// need to import and load the integrations
#import "SEGAnalyticsIntegrations.h"

static NSMutableDictionary *__registeredIntegrations = nil;
static SEGAnalytics *__sharedInstance = nil;

@interface SEGAnalyticsConfiguration ()

@property (nonatomic, copy, readwrite) NSString *writeKey;

@end

@implementation SEGAnalyticsConfiguration

+ (instancetype)configurationWithWriteKey:(NSString *)writeKey {
  return [[self alloc] initWithWriteKey:writeKey];
}

- (id)initWithWriteKey:(NSString *)writeKey {
  if (self = [self init]) {
    self.writeKey = writeKey;
  }
  return self;
}

- (instancetype)init {
  if (self = [super init]) {
    self.shouldUseLocationServices = NO;
    self.flushAt = 20;
    self.integrations = [NSMutableDictionary new];
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%p:%@, %@>", self, self.class, [self dictionaryWithValuesForKeys:@[ @"writeKey", @"shouldUseLocationServices", @"flushAt"] ]];
}

@end


@interface SEGAnalytics ()

@property (nonatomic, strong) NSDictionary *cachedSettings;
@property (nonatomic, strong) SEGAnalyticsConfiguration *configuration;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSMutableArray *messageQueue;
@property (nonatomic, strong) SEGAnalyticsRequest *settingsRequest;
@property (nonatomic, assign) BOOL enabled;

@end

@implementation SEGAnalytics

@synthesize cachedSettings = _cachedSettings;

+ (void)setupWithConfiguration:(SEGAnalyticsConfiguration *)configuration {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    __sharedInstance = [[self alloc] initWithConfiguration:configuration];
  });
}

#pragma mark - NSNotificationCenter Callback


- (void)onAppForeground:(NSNotification *)note {
  [self refreshSettings];
}

- (void)handleAppStateNotification:(NSNotification *)note {
  SEGLog(@"Application state change notification: %@", note.name);
  static NSDictionary *selectorMapping;
  static dispatch_once_t selectorMappingOnce;
  dispatch_once(&selectorMappingOnce, ^{
    selectorMapping = @{
      UIApplicationDidFinishLaunchingNotification:
      NSStringFromSelector(@selector(applicationDidFinishLaunching)),
      UIApplicationDidEnterBackgroundNotification:
      NSStringFromSelector(@selector(applicationDidEnterBackground)),
      UIApplicationWillEnterForegroundNotification:
      NSStringFromSelector(@selector(applicationWillEnterForeground)),
      UIApplicationWillTerminateNotification:
      NSStringFromSelector(@selector(applicationWillTerminate)),
      UIApplicationWillResignActiveNotification:
      NSStringFromSelector(@selector(applicationWillResignActive)),
      UIApplicationDidBecomeActiveNotification:
      NSStringFromSelector(@selector(applicationDidBecomeActive))
    };
  });
  SEL selector = NSSelectorFromString(selectorMapping[note.name]);
  if (selector)
    [self callIntegrationsWithSelector:selector arguments:nil options:nil];
}

#pragma mark - Public API

- (NSString *)description {
  return [NSString stringWithFormat:@"<%p:%@, %@>", self, [self class], [self dictionaryWithValuesForKeys:@[ @"configuration" ]]];
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId {
  [self identify:userId traits:nil options:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits {
  [self identify:userId traits:traits options:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {
  NSCParameterAssert(userId.length > 0 || traits.count > 0);

  [self callIntegrationsWithSelector:_cmd
                           arguments:@[userId ?: [NSNull null], SEGCoerceDictionary(traits), SEGCoerceDictionary(options)]
                             options:options];
}

- (void)track:(NSString *)event {
  [self track:event properties:nil options:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties {
  [self track:event properties:properties options:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
  NSCParameterAssert(event.length > 0);

  [self callIntegrationsWithSelector:_cmd
                           arguments:@[event, SEGCoerceDictionary(properties), SEGCoerceDictionary(options)]
                             options:options];
}

- (void)screen:(NSString *)screenTitle {
  [self screen:screenTitle properties:nil options:nil];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties {
  [self screen:screenTitle properties:properties options:nil];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options {
  NSCParameterAssert(screenTitle.length > 0);

  [self callIntegrationsWithSelector:_cmd
                           arguments:@[[NSString stringWithFormat:@"Viewed %@ Screen", screenTitle], SEGCoerceDictionary(properties), SEGCoerceDictionary(options)]
                             options:options];
}

- (void)group:(NSString *)groupId {
  [self group:groupId traits:nil options:nil];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits {
  [self group:groupId traits:traits options:nil];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options {
  [self callIntegrationsWithSelector:_cmd
                           arguments:@[groupId ?: [NSNull null], SEGCoerceDictionary(traits), SEGCoerceDictionary(options)]
                             options:options];
}

- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  NSParameterAssert(deviceToken != nil);
  [self callIntegrationsWithSelector:_cmd
                           arguments:@[deviceToken]
                             options:nil];
}

- (void)reset {
  [self callIntegrationsWithSelector:_cmd
                           arguments:nil
                             options:nil];
}

- (void)enable {
  _enabled = YES;
}

- (void)disable {
  _enabled = NO;
}

#pragma mark - Analytics Settings

- (NSDictionary *)cachedSettings {
  if (!_cachedSettings)
    _cachedSettings = [[NSDictionary alloc] initWithContentsOfURL:[self settingsURL]] ?: @{};
  return _cachedSettings;
}

- (void)setCachedSettings:(NSDictionary *)settings {
  _cachedSettings = [settings copy];
  [_cachedSettings ?: @{} writeToURL:self.settingsURL atomically:YES];
  [self updateIntegrationsWithSettings:settings];
}

- (void)updateIntegrationsWithSettings:(NSDictionary *)settings {
  for (id<SEGAnalyticsIntegration> integration in self.configuration.integrations.allValues)
    [integration updateSettings:settings[integration.name]];

  dispatch_specific_async(_serialQueue, ^{
    [self flushMessageQueue];
  });
}

- (void)refreshSettings {
  if (_settingsRequest)
    return;

  NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.segment.io/project/%@/settings", self.configuration.writeKey]]];
  [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
  [urlRequest setHTTPMethod:@"GET"];
  SEGLog(@"%@ Sending API settings request: %@", self, urlRequest);

  _settingsRequest = [SEGAnalyticsRequest startWithURLRequest:urlRequest completion:^{
    dispatch_specific_async(_serialQueue, ^{
      SEGLog(@"%@ Received API settings response: %@", self, _settingsRequest.responseJSON);

      if (!_settingsRequest.error) {
        [self setCachedSettings:_settingsRequest.responseJSON];
      }

      _settingsRequest = nil;
    });
  }];
}

#pragma mark - Class Methods

+ (instancetype)sharedAnalytics {
  NSCParameterAssert(__sharedInstance != nil);
  return __sharedInstance;
}

+ (void)debug:(BOOL)showDebugLogs {
  SEGSetShowDebugLogs(showDebugLogs);
}

+ (NSString *)version {
  return SEGStringize(ANALYTICS_VERSION);
}

#pragma mark - Private

- (BOOL)isIntegration:(id<SEGAnalyticsIntegration>)integration enabledInOptions:(NSDictionary *)options {
  if (options[integration.name]) {
    return [options[integration.name] boolValue];
  } else if (options[@"All"]) {
    return [options[@"All"] boolValue];
  } else if (options[@"all"]) {
    return [options[@"all"] boolValue];
  }
  return YES;
}

- (void)forwardSelector:(SEL)selector arguments:(NSArray *)arguments options:(NSDictionary *)options {
  if (!_enabled)
    return;

  for (id<SEGAnalyticsIntegration> integration in self.configuration.integrations.allValues)
    [self invokeIntegration:integration selector:selector arguments:arguments options:options];
}

- (void)invokeIntegration:(id <SEGAnalyticsIntegration>)integration selector:(SEL)selector arguments:(NSArray *)arguments options:(NSDictionary *)options {
  if (!integration.ready) {
    SEGLog(@"Not sending call to %@ because it isn't ready (enabled and initialized).", integration.name);
    return;
  }

  if (![integration respondsToSelector:selector]) {
    SEGLog(@"Not sending call to %@ because it doesn't respond to %@.", integration.name, NSStringFromSelector(selector));
    return;
  }

  if(![self isIntegration:integration enabledInOptions:options]) {
    SEGLog(@"Not sending call to %@ because it is disabled in options.", integration.name);
    return;
  }

  [[self invocationForSelector:selector arguments:arguments] invokeWithTarget:integration];
}

- (NSInvocation *)invocationForSelector:(SEL)selector arguments:(NSArray *)arguments {
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[SEGAnalyticsIntegration instanceMethodSignatureForSelector:selector]];
  invocation.selector = selector;
  for (int i=0; i < arguments.count; i++) {
    id argument = (arguments[i] == [NSNull null]) ? nil : arguments[i];
    [invocation setArgument:&argument atIndex:i+2];
  }
  return invocation;
}

- (void)queueSelector:(SEL)selector arguments:(NSArray *)arguments options:(NSDictionary *)options {
  [_messageQueue addObject:@[NSStringFromSelector(selector), arguments ?: @[], options ?: @{}]];
}

- (void)flushMessageQueue {
  if (_messageQueue.count) {

    for (NSArray *arr in _messageQueue)
      [self forwardSelector:NSSelectorFromString(arr[0]) arguments:arr[1] options:arr[2]];
    [_messageQueue removeAllObjects];
  }
}

- (void)callIntegrationsWithSelector:(SEL)selector arguments:(NSArray *)arguments options:(NSDictionary *)options  {
  dispatch_specific_async(_serialQueue, ^{
    // No cached settings, queue the API call

    if (!self.cachedSettings.count) {
      [self queueSelector:selector arguments:arguments options:options];
    }
      // Settings cached, flush message queue & new API call
    else {
      [self flushMessageQueue];
      [self forwardSelector:selector arguments:arguments options:options];
    }
  });
}

- (NSURL *)settingsURL {
  return SEGAnalyticsURLForFilename(@"analytics.settings.plist");
}

@end

@implementation SEGAnalytics (Internal)

- (id)initWithConfiguration:(SEGAnalyticsConfiguration *)configuration {
  NSCParameterAssert(configuration != nil);

  if (self = [self init]) {
    self.configuration = configuration;
    self.enabled = YES;
    self.serialQueue = dispatch_queue_create_specific("io.segment.analytics", DISPATCH_QUEUE_SERIAL);
    self.messageQueue = [[NSMutableArray alloc] init];

    [[[self class] registeredIntegrations] enumerateKeysAndObjectsUsingBlock:^(NSString *identifier, Class integrationClass, BOOL *stop) {
      self.configuration.integrations[identifier] = [[integrationClass alloc] initWithConfiguration:self.configuration];
    }];

    // Update settings on each integration immediately
    [self refreshSettings];

    // Attach to application state change hooks
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    // Update settings on foreground
    [nc addObserver:self selector:@selector(onAppForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

    // Pass through for application state change events
    for (NSString *name in @[UIApplicationDidEnterBackgroundNotification,
                             UIApplicationDidFinishLaunchingNotification,
                             UIApplicationWillEnterForegroundNotification,
                             UIApplicationWillTerminateNotification,
                             UIApplicationWillResignActiveNotification,
                             UIApplicationDidBecomeActiveNotification]) {
      [nc addObserver:self selector:@selector(handleAppStateNotification:) name:name object:nil];
    }
  }
  return self;
}

+ (NSDictionary *)registeredIntegrations {
  return [__registeredIntegrations copy];
}

+ (void)registerIntegration:(Class)integrationClass withIdentifier:(NSString *)identifer {
  NSCParameterAssert([NSThread isMainThread]);
  NSCParameterAssert(__sharedInstance == nil);
  NSCParameterAssert(identifer.length > 0);

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    __registeredIntegrations = [[NSMutableDictionary alloc] init];
  });

  __registeredIntegrations[identifer] = integrationClass;
}

@end

@implementation SEGAnalytics (Deprecated)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

+ (void)initializeWithWriteKey:(NSString *)writeKey {
  [self setupWithConfiguration:[SEGAnalyticsConfiguration configurationWithWriteKey:writeKey]];
}

- (id)initWithWriteKey:(NSString *)writeKey {
  return [self initWithConfiguration:[SEGAnalyticsConfiguration configurationWithWriteKey:writeKey]];
}

- (void)registerPushDeviceToken:(NSData *)deviceToken {
  [self registerForRemoteNotificationsWithDeviceToken:deviceToken];
}

#pragma clang diagnostic pop

@end
