//
//  BugsnagMetaData.m
//  Bugsnag Notifier
//
//  Created by Simon Maynard on 12/6/12.
//
//

#import "BugsnagMetaData.h"
#import "NSMutableDictionary+BSMerge.h"

@implementation BugsnagMetaData

- (id) init {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    return [self initWithDictionary:dict];
}

- (id) initWithDictionary:(NSMutableDictionary*)dict {
    if(self = [super init]) {
        self.dictionary = dict;
    }
    return self;
}

- (id) mutableCopyWithZone:(NSZone *)zone {
    @synchronized(self) {
        NSMutableDictionary *dict = [self.dictionary mutableCopy];
        return [[BugsnagMetaData alloc] initWithDictionary:dict];
    }
}

- (NSMutableDictionary *) getTab:(NSString*)tabName {
    @synchronized(self) {
        NSMutableDictionary *tab = [self.dictionary objectForKey:tabName];
        if(!tab) {
            tab = [NSMutableDictionary dictionary];
            [self.dictionary setObject:tab forKey:tabName];
        }
        return tab;
    }
}

- (void) clearTab:(NSString*)tabName {
    @synchronized(self) {
        [self.dictionary removeObjectForKey:tabName];
    }
}

- (void) mergeWith:(NSDictionary*)data {
    @synchronized(self) {
        [data enumerateKeysAndObjectsUsingBlock: ^(id key, id value, BOOL *stop) {
            if ([value isKindOfClass:[NSDictionary class]]) {
                [[self getTab:key] mergeWith: (NSDictionary *) value];
            } else {
                [[self getTab:@"customData"] setObject: value forKey: key];
            }
        }];
    }
}

@end
