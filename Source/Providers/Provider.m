// Provider.m
// Copyright 2013 Segment.io

#import "Provider.h"


@implementation Provider {

}

#pragma mark - Utilities

+ (NSDictionary *)aliasKeys:(NSDictionary *)dictionary withMap:(NSDictionary *)map
{
    NSMutableDictionary *mapped = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    for (id key in map) {
        [mapped setValue:[dictionary objectForKey:key] forKey:[map objectForKey:key]];
    }
    return mapped;
}

+ (NSNumber *)extractRevenue:(NSDictionary *)dictionary
{
    id revenueProperty = [dictionary objectForKey:@"revenue"];
    if (revenueProperty) {
        
        if ([revenueProperty isKindOfClass:[NSString class]]) {
            // Format the revenue.
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            return [formatter numberFromString:revenueProperty];
        }
        else if ([revenueProperty isKindOfClass:[NSNumber class]]) {
            return revenueProperty;
        }
        else {
            return nil;
        }
    }
    else {
        return nil;
    }
}


#pragma mark - State

- (void)start { }
- (void)stop { }

- (BOOL)ready
{
    return (self.valid && self.initialized);
}


#pragma mark - Settings

- (void)updateSettings:(NSDictionary *)settings
{
    // Store the settings and validate them.
    self.settings = settings;
    [self validate];

    // If we're ready, initialize the library.
    if (self.valid) {
        [self start];
        self.initialized = YES;
    }
    // Initialized but no longer valid settings (i.e. this integration got turned off).
    else if (self.initialized) {
        [self stop];
    }
}

- (void)validate
{
    self.valid = NO;
}



#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context { }

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context { }

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context { }



#pragma mark - Callbacks for app state changes

- (void)applicationDidEnterBackground { }
- (void)applicationWillEnterForeground { }
- (void)applicationWillTerminate { }
- (void)applicationWillResignActive { }
- (void)applicationDidBecomeActive { }



#pragma mark - NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ Analytics Provider:%@>", self.name, self.settings];
}

@end
