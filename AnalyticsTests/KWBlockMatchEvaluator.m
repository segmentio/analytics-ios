//
//  KWBlockMatchEvaluator.m
//  CLToolkit
//
//  Created by Tony Xiao on 8/24/13.
//  Copyright (c) 2013 Collections Labs, Inc. All rights reserved.
//

#import "KWBlockMatchEvaluator.h"

@implementation KWBlockMatchEvaluator

- (BOOL)matches:(id)object {
    return self.matchBlock(object);
}

+ (id)evaluatorWithBlock:(BOOL (^)(id object))matchBlock {
    NSParameterAssert(matchBlock);
    KWBlockMatchEvaluator *evaluator = [[self alloc] init];
    evaluator.matchBlock = matchBlock;
    return evaluator;
}

@end
