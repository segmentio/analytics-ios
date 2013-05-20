//
//  BugsnagHelpers.h
//  Bugsnag Notifier
//
//  Created by Simon Maynard on 12/6/12.
//
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#   define BugLog(__FORMAT__, ...) NSLog(__FORMAT__, ##__VA_ARGS__)
#else
#   define BugLog(...) do {} while (0)
#endif
