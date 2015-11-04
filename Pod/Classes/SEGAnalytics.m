#import "SEGAnalytics.h"
#import "SEGIdentifyPayload.h"
#import "SEGTrackPayload.h"
#import "SEGScreenPayload.h"
#import "SEGAliasPayload.h"
#import "SEGIdentifyPayload.h"
#import "SEGGroupPayload.h"
#import "SEGExecutor.h"
#import "SEGSerialExecutor.h"
#import "SEGClient.h"

static SEGAnalytics *__sharedInstance = nil;

@interface SEGAnalyticsConfiguration ()

@property (nonatomic, readonly) NSMutableArray *factories;

@end

@implementation SEGAnalyticsConfiguration

+ (instancetype)configurationWithWriteKey:(NSString *)writeKey
{
    return [[self alloc] initWithWriteKey:writeKey];
}

- (id)initWithWriteKey:(NSString *)writeKey
{
    if (self = [self init]) {
        _writeKey = writeKey;
        _factories = [NSMutableArray array];
        self.shouldUseLocationServices = NO;
        self.enableAdvertisingTracking = YES;
        self.flushAt = 20;
    }
    return self;
}

-(void)use:(id<SEGIntegrationFactory>)factory
{
    [self.factories addObject:factory];
}

@end

@interface SEGAnalytics ()

@property (nonatomic, assign) NSArray *writeKey;

@property (nonatomic, strong) NSArray *factories;

@property (nonatomic, strong) id<SEGExecutor> executor;

@property (nonatomic, strong) SEGClient *client;

@property (nonatomic, strong) NSDictionary *cachedSettings;

@end

@implementation SEGAnalytics

+ (void)setupWithConfiguration:(SEGAnalyticsConfiguration *)configuration
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[self alloc] initWithConfiguration:configuration];
    });
}

- (instancetype)initWithConfiguration:(SEGAnalyticsConfiguration *)configuration {
    if (self = [self init]) {
        // todo:
        _executor = [[SEGSerialExecutor alloc] initWithName:@"com.segment.analytics"];
        _factories = [[configuration factories] copy];
        _client = [[SEGClient alloc] initWithWriteKey:configuration.writeKey];
        
        
    }
    return self;
}

+(NSURL *)URLForFileName:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
                                                         NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *supportPath = [paths firstObject];
    if (![[NSFileManager defaultManager] fileExistsAtPath:supportPath
                                              isDirectory:NULL]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:supportPath
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error]) {
            // SEGLog(@"error: %@", error.localizedDescription);
        }
    }
    return [[NSURL alloc] initFileURLWithPath:[supportPath stringByAppendingPathComponent:fileName]];
}

-(NSDictionary *)getSettings
{
    NSURL *file = [SEGAnalytics URLForFileName:@"analytics.settings.v2.plist"];
    self.cachedSettings = [[NSDictionary alloc] initWithContentsOfURL:file];
    if (self.cachedSettings == nil) {
        self.cachedSettings = [self.client settings];
        if (self.cachedSettings == nil) {
            // No cached settings. Enable Segment.
            self.cachedSettings = @{
                                     @"integrations" : @{
                                            @"Segment.io": @{
                                                    @"apiKey" : self.writeKey
                                            }
                                     },
                                     @"plan": @{}
                                   };
        }
    }
    return [self.cachedSettings copy];
}

- (void)identify:(NSString *)userId
{
    [self identify:userId traits:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits
{
    [self identify:userId traits:traits options:nil];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc] initWithUserId:userId traits:traits context:options[@"context"]];
    // todo:
}

- (void)track:(NSString *)event
{
    [self track:event properties:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties
{
    [self track:event properties:properties options:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:event properties:properties context:options[@"context"]];

    // todo:
}

- (void)group:(NSString *)groupId
{
    [self group:groupId traits:nil];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits
{
    [self group:groupId traits:traits options:nil];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    SEGGroupPayload *payload = [[SEGGroupPayload alloc] initWithGroupId:groupId traits:traits context:options[@"context"]];
    // todo:
}

- (void)screen:(NSString *)name;
{
    [self screen:name properties:nil];
}

- (void)screen:(NSString *)name properties:(NSDictionary *)properties;
{
    [self screen:name properties:properties options:nil];
}

- (void)screen:(NSString *)name properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    SEGScreenPayload *payload = [[SEGScreenPayload alloc] initWithName:name properties:properties context:options[@"context"]];
}

- (void)alias:(NSString *)newId
{
    [self alias:newId options:nil];
}

- (void)alias:(NSString *)newId options:(NSDictionary *)options
{
    SEGAliasPayload *payload = [[SEGAliasPayload alloc] initWithNewId:newId context:options[@"context"]];
    // todo:
}

@end
