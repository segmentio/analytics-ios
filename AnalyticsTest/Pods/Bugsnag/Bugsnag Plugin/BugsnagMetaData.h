//
//  BugsnagMetaData.h
//  Bugsnag Notifier
//
//  Created by Simon Maynard on 12/6/12.
//
//

#import <Foundation/Foundation.h>

@interface BugsnagMetaData : NSObject < NSMutableCopying >

@property (strong) NSMutableDictionary *dictionary;

- (id) initWithDictionary:(NSMutableDictionary*)dict;
- (NSMutableDictionary *) getTab:(NSString*)tabName;
- (void) clearTab:(NSString*)tabName;
- (void) mergeWith:(NSDictionary*)data;

@end
