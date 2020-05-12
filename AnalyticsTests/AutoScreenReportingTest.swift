//
// Created by David Whetstone on 2018-11-04.
// Copyright (c) 2018 Segment. All rights reserved.
//

import Foundation
import Quick
import Nimble
import SwiftTryCatch
@testable import Analytics

class AutoScreenReportingTests: QuickSpec {

  override func spec() {

    var window: UIWindow!
    var rootVC: UIViewController!

    beforeEach {
      let config = SEGAnalyticsConfiguration(writeKey: "foobar")
      config.trackApplicationLifecycleEvents = true
      config.recordScreenViews = true

      window = UIWindow()
      rootVC = UIViewController()
      window.addSubview(rootVC.view)
    }


    describe("given a single view controller") {

      it("seg_topViewController returns that view controller") {
        let actualVC = UIViewController.seg_topViewController(rootVC)
        expect(actualVC) === rootVC
      }
    }

    describe("given a presented view controller") {

      var expectedVC: UIViewController!

      beforeEach {
        expectedVC = UIViewController()
        rootVC.present(expectedVC, animated: false)
      }

      it("seg_topViewController returns the presented view controller") {
        let actualVC = UIViewController.seg_topViewController(rootVC)
        expect(actualVC) === expectedVC
      }
    }

    describe("given a pushed view controller") {

      var expectedVC: UIViewController!

      beforeEach {
        expectedVC = UIViewController()
        let nc = UINavigationController()
        rootVC.present(nc, animated: false)
        nc.pushViewController(expectedVC, animated: false)
      }

      it("seg_topViewController returns the pushed view controller") {
        let actualVC = UIViewController.seg_topViewController(rootVC)
        expect(actualVC) === expectedVC
      }
    }

    describe("given a child of a UITabBarController") {

      var expectedVC: UIViewController!

      beforeEach {
        expectedVC = UIViewController()
        let tabBarController = UITabBarController()
        rootVC.present(tabBarController, animated: false)
        tabBarController.viewControllers = [UIViewController(), expectedVC, UIViewController()]
        tabBarController.selectedIndex = 1
      }

      it("seg_topViewController returns the currently selected view controller") {
        let actualVC = UIViewController.seg_topViewController(rootVC)
        expect(actualVC) === expectedVC
      }
    }

    describe("given a child of a custom container view controller conforming to SEGScreenReporting") {

      class CustomContainerViewController: UIViewController, SEGScreenReporting {
        var selectedIndex: Int = 0
        var seg_mainViewController: UIViewController? {
          return childViewControllers[selectedIndex]
        }
      }

      var expectedVC: UIViewController!

      beforeEach {
        expectedVC = UIViewController()
        let containerVC = CustomContainerViewController()
        rootVC.present(containerVC, animated: false)
        [UIViewController(), expectedVC, UIViewController()].forEach { child in
          containerVC.addChildViewController(child)
        }
        containerVC.selectedIndex = 1
      }

      it("seg_topViewController returns the currently selected view controller") {
        let actualVC = UIViewController.seg_topViewController(rootVC)
        expect(actualVC) === expectedVC
      }
    }

    describe("given a child of a container view controller NOT conforming to SEGScreenReporting") {

      var expectedVC: UIViewController!

      beforeEach {
        expectedVC = UIViewController()
        let containerVC = UIViewController()
        rootVC.present(containerVC, animated: false)
        [expectedVC, UIViewController(), UIViewController()].forEach { child in
          containerVC.addChildViewController(child)
        }
      }

      it("seg_topViewController returns the first child view controller") {
        let actualVC = UIViewController.seg_topViewController(rootVC)
        expect(actualVC) === expectedVC
      }
    }
  }
}


