//
//  SIOBluetooth.h
//  Analytics
//
//  Created by Travis Jeffery on 4/23/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SEGBluetooth : NSObject

- (BOOL)hasKnownState;
- (BOOL)isEnabled;

@end
