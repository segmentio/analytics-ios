//
//  NSMutableDictionary+BSMerge.m
//  Bugsnag Notifier
//
//  Created by Simon Maynard on 12/6/12.
//
//

#import "NSMutableDictionary+BSMerge.h"

@implementation NSMutableDictionary (BSMerge)
+ (void) merge: (NSDictionary*) source into:(NSMutableDictionary*) destination {
    [source enumerateKeysAndObjectsUsingBlock: ^(id key, id value, BOOL *stop) {
        if ([destination objectForKey:key] && [value isKindOfClass:[NSDictionary class]]) {
            [[destination objectForKey: key] mergeWith: (NSDictionary *) value];
        } else {
            [destination setObject: value forKey: key];
        }
    }];
}

- (void) mergeWith: (NSDictionary *) source {
    [[self class] merge:source into: self];
}

@end
