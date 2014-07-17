//
//  SEGEcommerce.h
//  Analytics
//
//  Created by Travis Jeffery on 7/17/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SEGEcommerce <NSObject>

- (void)viewedProduct;
- (void)removedProduct;
- (void)addedProduct;
- (void)completedOrder;

@end
