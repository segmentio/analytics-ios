//
//  UIViewController+SegScreenTest.h
//  Analytics
//
//  Created by David Whetstone on 7/15/19.
//  Copyright © 2019 Segment. All rights reserved.
//

#ifndef UIViewController_SegScreenTest_h
#define UIViewController_SegScreenTest_h


@interface UIViewController (Testing)
/// We need to expose this normally private method to tests, as the public facing
/// `+ (UIViewController *)seg_topViewController` relies on the `application` property
/// of `SEGAnalyticsConfiguration`, which won't be set in these tests.
+ (UIViewController *)seg_topViewController:(UIViewController *)rootViewController;
@end


#endif /* UIViewController_SegScreenTest_h */
