Releasing
=========

 1. Update the version in `SEGAnalytics.m` and `Analytics.podspec` to a non-beta version.
 2. Update the `CHANGELOG.md` for the impending release.
 3. Update the `README.md` with the new version.
 4. `git commit -am "Prepare for release X.Y.Z."` (where X.Y.Z is the new version)
 5. `git tag -a X.Y.Z -m "Version X.Y.Z"` (where X.Y.Z is the new version)
 6. `git push && git push --tags`
 6. `pod trunk push Analytics.podspec --allow-warnings`
 7. Update the version in `SEGAnalytics.m` and `Analytics.podspec` to the next beta version.
 8. `git commit -am "Prepare next development version."`
 9. `git push`
