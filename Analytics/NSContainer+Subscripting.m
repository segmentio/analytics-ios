//
//  NSContainer+Subscripting.m
//
//  Created by Markus Emrich on 10.08.12.
//  Copyright 2012 nxtbgthng. All rights reserved.
//

#if !( defined(__IPHONE_6_0) || defined(__IPHONE_7_0) ) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0

#import "NSContainer+Subscripting.h"

@implementation NSArray (Subscripting)
- (id)objectAtIndexedSubscript:(NSInteger)index {
    return [self objectAtIndex:index];
}
@end

@implementation NSMutableArray (MutableSubscripting)
- (void)setObject:(id)anObject atIndexedSubscript:(NSUInteger)index {
    if (index < self.count)
        [self replaceObjectAtIndex:index withObject:anObject];
    else
        [self insertObject:anObject atIndex:index];
}
@end

@implementation NSDictionary (Subscripting)
-(id)objectForKeyedSubscript:(id)key {
    return [self objectForKey: key];
}
@end

@implementation NSMutableDictionary (MutableSubscripting)
- (void)setObject:(id)object forKeyedSubscript:(id)key {
    [self setObject:object forKey: key];
}
@end

#endif