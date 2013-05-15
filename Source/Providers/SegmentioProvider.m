// SegmentioProvider.m
// Copyright 2013 Segment.io

#import "SegmentioProvider.h"

#import "Segmentio.h"


@implementation SegmentioProvider {

}

#pragma mark - Initialization

+ (instancetype)withSecret:(NSString *)secret
{
    return [[self alloc] initWithSecret:secret];
}

- (id)initWithSecret:(NSString *)secret
{
    if (self = [self init]) {
        self.name = @"Segmentio";
        self.enabled = YES;
        self.valid = NO;
        self.initialized = NO;
        
        self.settings = [NSDictionary dictionaryWithObjectsAndKeys:secret, @"secret", nil];
        [self start];
    }
    return self;
}

- (void)start
{
    // Re-validate
    [self validate];

    // Check that all states are go
    if (self.enabled && self.valid) {
        [Segmentio withSecret:[self.settings objectForKey:@"secret"]];
        self.initialized = YES;
    }
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasSecret = [self.settings objectForKey:@"secret"] != nil;
    self.valid = hasSecret;
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context
{
    [[Segmentio sharedInstance] identify:userId traits:traits context:context];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    [[Segmentio sharedInstance] track:event properties:properties context:context];
}

- (void)alias:(NSString *)from to:(NSString *)to context:(NSDictionary *)context
{
    [[Segmentio sharedInstance] alias:from to:to context:context];
}


@end
