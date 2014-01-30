//
//  KWBlockMatchEvaluator.h
//  CLToolkit
//
//  Created by Tony Xiao on 8/24/13.
//  Copyright (c) 2013 Collections Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KWBlockMatchEvaluator : NSObject

@property (nonatomic, copy) BOOL(^matchBlock)(id object);

- (BOOL)matches:(id)object;

+ (id)evaluatorWithBlock:(BOOL (^)(id object))matchBlock;

@end
