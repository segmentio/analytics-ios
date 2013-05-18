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
        self.name = @"Segment.io";
        self.enabled = YES;
        self.valid = NO;
        self.initialized = NO;
        
        self.settings = [NSDictionary dictionaryWithObjectsAndKeys:secret, @"secret", nil];
        [self validate];
        [self start];
        self.initialized = YES;
    }
    return self;
}

- (void)start
{
    [Segmentio withSecret:[self.settings objectForKey:@"secret"]];
    NSLog(@"SegmentioProvider initialized.");
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


@end
