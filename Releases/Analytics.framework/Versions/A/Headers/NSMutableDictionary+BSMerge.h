//
//  NSMutableDictionary+BSMerge.h
//  Bugsnag Notifier
//
//  Created by Simon Maynard on 12/6/12.
//
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (BSMerge)
+ (void) merge: (NSDictionary*) source into:(NSMutableDictionary*) destination;

- (void) mergeWith: (NSDictionary *) source;
@end
