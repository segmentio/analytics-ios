// UniqueIdentifier.m
// Copyright 2013 Segment.io

#import "UniqueIdentifier.h"

@implementation UniqueIdentifier

+ (NSString *)getUniqueIdentifier
{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        // For iOS6 and later
        return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    } else {
        // For iOS5 and earlier
        return [[UIDevice currentDevice] uniqueIdentifier];
    }
}

@end