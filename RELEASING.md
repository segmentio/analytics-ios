Releasing
========

 1. Update the version in `SEGAnalytics.m`, `Analytics.podspec` and `Analytics/Info.plist` to the next release version.
 2. Update the `CHANGELOG.md` for the impending release.
 3. `git commit -am "Prepare for release X.Y.Z."` (where X.Y.Z is the new version).
 4. `git tag -a X.Y.Z -m "Version X.Y.Z"` (where X.Y.Z is the new version).
 5. `git push && git push --tags`.
 6. `pod trunk push Analytics.podspec`.
 7. Update the version in `SEGAnalytics.m`, `Analytics.podspec` and `Analytics/Info.plist` to the next SNAPSHOT version.
 8. `git commit -am "Prepare next development version."`
 9. `git push`.
