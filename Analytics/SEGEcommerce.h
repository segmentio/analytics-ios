//
//  SEGEcommerce.h
//  Analytics
//
//  Created by Travis Jeffery on 7/17/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SEGEcommerce <NSObject>
@optional
- (void)viewedProduct:(NSDictionary *)properties;
- (void)removedProduct:(NSDictionary *)properties;
- (void)addedProduct:(NSDictionary *)properties;
- (void)completedOrder:(NSDictionary *)properties;
@end
