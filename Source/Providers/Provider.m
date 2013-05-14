// Provider.m
// Copyright 2013 Segment.io

#import "Provider.h"


@implementation Provider {

}

#pragma mark - Initialization

- (void)start { }

#pragma mark - Enabled State

- (void)enable
{
    self.enabled = YES;
}

- (void)disable
{
    self.enabled = NO;
}

- (BOOL)ready
{
    return (self.enabled && self.valid && self.initialized);
}


#pragma mark - Settings

- (void)updateSettings:(NSDictionary *)settings
{
    self.settings = settings;
    [self validate];
    [self start];
}

- (void)validate
{
    self.valid = NO;
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context { }

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context { }

- (void)alias:(NSString *)from to:(NSString *)to context:(NSDictionary *)context { }



#pragma mark - NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ Analytics Provider:%@>", self.name, self.settings];
}

@end
