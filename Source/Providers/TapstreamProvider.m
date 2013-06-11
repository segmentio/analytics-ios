// TapstreamProvider.m

#import "TapstreamProvider.h"
#import "TSTapstream.h"

#ifdef DEBUG
#define AnalyticsDebugLog(...) NSLog(__VA_ARGS__)
#else
#define AnalyticsDebugLog(...)
#endif

@interface TapstreamProvider()
- (TSEvent *)makeEvent:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context;
@end

@implementation TapstreamProvider {    
}

#pragma mark - Initialization

+ (instancetype)withNothing
{
    return [[self alloc] initWithNothing];
}

- (id)initWithNothing
{
    if (self = [self init]) {
        self.name = @"Tapstream";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    TSConfig *config = [TSConfig configWithDefaults];

    // Load any values that the TSConfig object supports
    for(NSString *key in self.settings) {
        if([config respondsToSelector:NSSelectorFromString(key)]) {
            [config setValue:[self.settings objectForKey:key] forKey:key];
        }
    }

    NSString *accountName = [self.settings objectForKey:@"accountName"];
    NSString *developerSecret = [self.settings objectForKey:@"developerSecret"];
    
    [TSTapstream createWithAccountName:accountName developerSecret:developerSecret config:config];

    AnalyticsDebugLog(@"TapstreamProvider initialized.");
}


#pragma mark - Settings

- (void)validate
{
    // Require accountName and developerSecret
    NSString *accountName = [self.settings objectForKey:@"accountName"];
    NSString *developerSecret = [self.settings objectForKey:@"developerSecret"];
    self.valid = accountName != nil && developerSecret != nil;
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context
{
    // Tapstream doesn't use an explicit user identification event
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    TSEvent *e = [self makeEvent:event properties:properties context:context];

    AnalyticsDebugLog(@"Sending event to Tapstream");
    [[TSTapstream instance] fireEvent:e];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    NSString *screenEventName = [@"screen-" stringByAppendingString:screenTitle];
    TSEvent *e = [self makeEvent:screenEventName properties:properties context:context];

    AnalyticsDebugLog(@"Sending screen event Tapstream");
    [[TSTapstream instance] fireEvent:e];
}



- (TSEvent *)makeEvent:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    // Add support for Tapstream's "one-time-only" events by looking for a field in the context dict.
    // One time only will be false by default.
    NSNumber *oneTimeOnly = [context objectForKey:@"oneTimeOnly"];
    BOOL oto = oneTimeOnly != nil && [oneTimeOnly boolValue] == YES;

    TSEvent *e = [TSEvent eventWithName:event oneTimeOnly:oto];

    for(NSString *key in properties)
    {
        id value = [properties objectForKey:key];
        if([value isKindOfClass:[NSString class]])
        {
            [e addValue:(NSString *)value forKey:(NSString *)key];
        }
        else if([value isKindOfClass:[NSNumber class]])
        {
            NSNumber *number = (NSNumber *)value;
            
            if(strcmp([number objCType], @encode(int)) == 0)
            {
                [e addIntegerValue:[number intValue] forKey:key];
            }
            else if(strcmp([number objCType], @encode(uint)) == 0)
            {
                [e addUnsignedIntegerValue:[number unsignedIntValue] forKey:key];
            }
            else if(strcmp([number objCType], @encode(double)) == 0 ||
                strcmp([number objCType], @encode(float)) == 0)
            {
                [e addDoubleValue:[number doubleValue] forKey:key];
            }
            else if(strcmp([number objCType], @encode(BOOL)) == 0)
            {
                [e addBooleanValue:[number boolValue] forKey:key];
            }
            else
            {
                AnalyticsDebugLog(@"Tapstream Event cannot accept an NSNumber param holding this type, skipping param");
            }
        }
        else
        {
            AnalyticsDebugLog(@"Tapstream Event cannot accept a param of this type, skipping param");
        }
    }

    return e;
}

@end
