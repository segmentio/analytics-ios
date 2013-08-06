//
//  NSDictionary+BSJSON.h
//  Bugsnag Notifier
//
//  Created by Simon Maynard on 12/6/12.
//
//

#import <Foundation/Foundation.h>

@interface NSDictionary (BSJSON)
- (NSString*) toJSONRepresentation;
@end
