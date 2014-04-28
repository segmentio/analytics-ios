// Provider.m
// Copyright 2013 Segment.io

#import "AnalyticsProvider.h"

@implementation AnalyticsProvider

- (void)start { }
- (void)stop { }

- (void)validate {
    self.valid = NO;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ Analytics Provider:%@>", self.name, self.settings];
}

#pragma mark - Analytics Provider Default Implementation

- (id)initWithAnalytics:(Analytics *)analytics {
    return [self init];
}

- (BOOL)ready {
    return (self.valid && self.initialized);
}

- (void)updateSettings:(NSDictionary *)settings {
    // Store the settings and validate them.
    self.settings = settings;
    [self validate];

    // If we're ready, initialize the library.
    if (self.valid) {
        [self start];
        self.initialized = YES;
    } else if (self.initialized) {
         // Initialized but no longer valid settings (i.e. this integration got turned off).
        [self stop];
    }
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options { }
- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options { }
- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options { }
- (void)reset { }

- (void)applicationDidEnterBackground { }
- (void)applicationWillEnterForeground { }
- (void)applicationWillTerminate { }
- (void)applicationWillResignActive { }
- (void)applicationDidBecomeActive { }
- (void)applicationDidFinishLaunching {}

#pragma mark Class Methods

+ (NSDictionary *)map:(NSDictionary *)dictionary withMap:(NSDictionary *)map {
    NSMutableDictionary *mapped = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    for (id key in map) {
        [mapped setValue:[dictionary objectForKey:key] forKey:[map objectForKey:key]];
        [mapped setValue:nil forKey:key];
    }
    return mapped;
}

+ (NSNumber *)extractRevenue:(NSDictionary *)dictionary {
    return [AnalyticsProvider extractRevenue:dictionary withKey:@"revenue"];
}

+ (NSNumber *)extractRevenue:(NSDictionary *)dictionary withKey:(NSString *)key {
    id revenueProperty = [dictionary objectForKey:key];
    if (revenueProperty) {
        if ([revenueProperty isKindOfClass:[NSString class]]) {
            // Format the revenue.
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            return [formatter numberFromString:revenueProperty];
        } else if ([revenueProperty isKindOfClass:[NSNumber class]]) {
            return revenueProperty;
        }
    }
    return nil;
}

@end
