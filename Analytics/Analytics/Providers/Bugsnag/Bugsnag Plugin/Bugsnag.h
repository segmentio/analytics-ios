#import <Foundation/Foundation.h>

@interface Bugsnag : NSObject {
    @private
    NSString *_appVersion;
    NSString *_userId;
    NSString *_context;
    NSString *_uuid;
}

+ (void) startBugsnagWithApiKey:(NSString*)apiKey;
+ (void) notify:(NSException *)exception;
+ (void) notify:(NSException *)exception withData:(NSDictionary*)metaData;

+ (void) setUserAttribute:(NSString*)attributeName withValue:(id)value;
+ (void) clearUser;

+ (void) addAttribute:(NSString*)attributeName withValue:(id)value toTabWithName:(NSString*)tabName;
+ (void) clearTabWithName:(NSString*)tabName;

+ (Bugsnag *)instance;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *appVersion;
@property (nonatomic, copy) NSString *releaseStage;
@property (nonatomic, copy) NSString *context;
@property (copy) NSString *apiKey;
@property (nonatomic) BOOL enableSSL;
@property (nonatomic) BOOL autoNotify;
@property (nonatomic, strong) NSArray *notifyReleaseStages;
@property (unsafe_unretained, readonly) NSString *uuid;
@end