#import "SEGAnalytics.h"

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

@property (nonatomic, readwrite) NSMutableArray *factories;

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
    }
    return self;
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

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    // todo:
}

- (void)alias:(NSString *)newId
{
    [self alias:newId options:nil];
}

- (void)alias:(NSString *)newId options:(NSDictionary *)options
{
    // todo:
}

@end
