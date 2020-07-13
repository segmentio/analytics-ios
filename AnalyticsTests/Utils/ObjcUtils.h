//
//  ObjcUtils.h
//  AnalyticsTests
//
//  Created by Brandon Sneed on 7/13/20.
//  Copyright © 2020 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>

NSException * _Nullable objc_tryCatch(void (^ _Nonnull block)(void));
