//
//  NSContainer+Subscripting.h
//
//  Created by Markus Emrich on 10.08.12.
//  Copyright 2012 nxtbgthng. All rights reserved.
//

#if !defined(__IPHONE_6_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0

#import "NSContainer+Subscripting.h"

@interface NSArray (Subscripting)
- (id)objectAtIndexedSubscript:(NSInteger)index;
@end

@interface NSMutableArray (MutableSubscripting)
- (void)setObject:(id)anObject atIndexedSubscript:(NSUInteger)index;
@end

@interface NSDictionary (Subscripting)
- (id)objectForKeyedSubscript:(id)key;
@end

@interface NSMutableDictionary (MutableSubscripting)
- (void)setObject:(id)object forKeyedSubscript:(id)key;
@end

#endif