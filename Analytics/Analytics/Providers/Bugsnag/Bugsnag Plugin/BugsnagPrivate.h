#import <Foundation/Foundation.h>
#import "BugsnagMetaData.h"

@interface Bugsnag ()
- (id) init;
- (BOOL) shouldAutoNotify;

@property (strong) BugsnagMetaData *metaData;
@property (strong) NSDate *sessionStartDate;
@property (unsafe_unretained, readonly) NSNumber *sessionLength;
@property BOOL inForeground;
@end