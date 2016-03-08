#!/bin/bash

if ! which xcodebuild >/dev/null; then
  echo "xcodebuild is not available. Install it from https://itunes.apple.com/us/app/xcode/id497799835"
  exit 1
fi

if ! which gem >/dev/null; then
  echo "rubygem is not available. Install it from https://rubygems.org/pages/download"
  exit 1
fi

if ! which pod >/dev/null; then
  echo "installing cocoapods..."
  gem install cocoapods
fi

if ! which xcpretty >/dev/null; then
  echo "installing xcpretty."
  gem install xcpretty
fi

echo "dependencies installed. verifying build."
make test
