//
//  BugsnagEvent.h
//  Bugsnag Notifier
//
//  Created by Simon Maynard on 12/6/12.
//
//

#import <Foundation/Foundation.h>

@interface BugsnagEvent : NSObject
+ (NSArray *) outstandingReports;
+ (NSDictionary*) generateEventFromException:(NSException*)exception withMetaData:(NSDictionary*)passedMetaData;
+ (NSDictionary*) generateEventFromErrorClass:(NSString*)errorClass
                                 errorMessage:(NSString*)errorMessage
                                   stackTrace:(NSArray*)rawStacktrace
                                     metaData:(NSDictionary*)passedMetaData;
+ (NSArray*) getCallStackFromFrames:(void*)frames andCount:(int)count startingAt:(int)start;
+ (void) writeEventToDisk:(NSDictionary*)event;
@end
