// Provider.m
// Copyright 2013 Segment.io

#import "Provider.h"


@interface Provider ()

@property(nonatomic, strong) NSString *name;
@property(nonatomic, assign) BOOL enabled;
@property(nonatomic, assign) BOOL valid;
@property(nonatomic, strong) NSDictionary *settings;

@end


@implementation Provider {

}

#pragma mark - Enabled State

- (void)enable
{
    self.enabled = YES;
}

- (void)disable
{
    self.enabled = NO;
}


#pragma mark - Settings

- (void)setSettings:(NSDictionary *)settings
{
    self.settings = settings;
    [self validate];
}

- (void)validate
{
    self.valid = NO;
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits { }

- (void)track:(NSString *)event properties:(NSDictionary *)properties { }

- (void)alias:(NSString *)from to:(NSString *)to { }



#pragma mark - NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ Analytics Provider:%@>", self.name, self.settings];
}

@end
