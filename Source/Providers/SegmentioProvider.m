// SegmentioProvider.m
// Copyright 2013 Segment.io

#import "SegmentioProvider.h"

@implementation SegmentioProvider {

}

#pragma mark - Initialization

+ (instancetype)withNothing
{
    return [[self alloc] initWithNothing];
}

- (id)initWithNothing
{
    if (self = [self init]) {
        _name = @"Segmentio";
        // TODO all the other initialization
    }
    return self;
}


#pragma mark - Settings

- (void)validate
{
    // TODO add validation
    self.valid = YES;
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits
{
    // TODO copy in the identify code
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties
{
    // TODO copy in the track code
}

- (void)alias:(NSString *)from to:(NSString *)to
{
    // TODO copy in the alias code
}


@end
