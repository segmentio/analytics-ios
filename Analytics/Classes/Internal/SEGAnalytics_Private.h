//
//  SEGAnalytics_Private.h
//  Analytics
//
//  Created by Brandon Sneed on 1/28/20.
//  Copyright © 2020 Segment. All rights reserved.
//

#ifndef SEGAnalytics_Private_h
#define SEGAnalytics_Private_h

#import "SEGAnalytics.h"

@interface SEGAnalytics(Private)
- (void)run:(SEGEventType)eventType payload:(SEGPayload *)payload;
@end

#endif /* SEGAnalytics_Private_h */
