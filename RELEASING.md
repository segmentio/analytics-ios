Releasing
========

 1. Update the version in `SEGAnalytics.m`, `Analytics.podspec` and `Analytics/Info.plist` to the next release version.
 2. Update the `CHANGELOG.md` for the impending release.
 3. `git commit -am "Prepare for release X.Y.Z."` (where X.Y.Z is the new version).
 4. `git tag -a X.Y.Z -m "Version X.Y.Z"` (where X.Y.Z is the new version).
 5. `git push && git push --tags`.
 6. `pod trunk push Analytics.podspec`.
 7. Next we'll create a dynamic framework for manual installation leveraging Carthage
     * `cd Examples/CarthageExample`
     * Update `Cartfile` first line to the correct tag `X.Y.Z` that just got pushed to github
     * `make clean` to be safe then `make build`
     * Zip `Carthage/Builds/iOS/Analytics.framework` into `Analytics.framework.zip`
     * Zip `Carthage/Builds/iOS/Analytics.dSYM` into `Analytics.dSYM.zip`
 8. Create a new github release at https://github.com/segmentio/analytics-ios/releases
     * Add latest version information from `CHANGELOG.md`
     * Upload `Analytics.framework.zip` and `Analytics.dSYM.zip` into binaries section to make available for users to download
 8. Update the version in `SEGAnalytics.m`, `Analytics.podspec` and `Analytics/Info.plist` to the next SNAPSHOT version.
 9. `git commit -am "Prepare next development version."`
 10. `git push`.
