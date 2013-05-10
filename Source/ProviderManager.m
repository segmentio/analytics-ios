// ProviderManager.m
// Copyright 2013 Segment.io

#import "ProviderManager.h"


@implementation Analytics {

}

#pragma mark - Initializiation

- (id)initWithSettings:(NSDictionary *)settings
{
    if (self = [self init]) {
        _settings = settings;
    }
    return self;
}



#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits { }

- (void)track:(NSString *)event properties:(NSDictionary *)properties { }

- (void)alias:(NSString *)from to:(NSString *)to { }



#pragma mark - NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<Analytics ProviderManager:%@>", self.settings];
}

@end
