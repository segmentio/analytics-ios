
// Adopted from and credit goes to https://gist.github.com/MattesGroeger/4066084

#import <Kiwi/Kiwi.h>

@interface KWBlockMatchEvaluator : NSObject

@property (nonatomic, copy) BOOL(^matchBlock)(id object);

- (BOOL)matches:(id)object;

+ (id)evaluatorWithBlock:(BOOL (^)(id object))matchBlock;

@end

@interface KWNotificationMatcher : KWMatcher

- (void)receiveNotification:(NSString *)name;
- (void)receiveNotification:(NSString *)name withCount:(NSUInteger)aCount;
- (void)receiveNotification:(NSString *)name withCountAtLeast:(NSUInteger)aCount;
- (void)receiveNotification:(NSString *)name withCountAtMost:(NSUInteger)aCount;

- (void)receiveNotification:(NSString *)name withUserInfo:(NSDictionary *)userInfo;
- (void)receiveNotification:(NSString *)name withCount:(NSUInteger)aCount userInfo:(NSDictionary *)userInfo;
- (void)receiveNotification:(NSString *)name withCountAtLeast:(NSUInteger)aCount userInfo:(NSDictionary *)userInfo;
- (void)receiveNotification:(NSString *)name withCountAtMost:(NSUInteger)aCount userInfo:(NSDictionary *)userInfo;

@end