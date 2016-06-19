#!/bin/bash

if ! which xcodebuild >/dev/null; then
  echo "xcodebuild is not available. Install it from https://itunes.apple.com/us/app/xcode/id497799835"
  exit 1
else
  echo "xcodebuild already installed"
fi

if ! which gem >/dev/null; then
  echo "rubygems is not available. Install it from https://rubygems.org/pages/download"
  exit 1
else
  echo "rubygems already installed"
fi

if ! which brew >/dev/null; then
  echo "homebrew is not available. Install it from http://brew.sh"
  exit 1
else
  echo "homebrew already installed"
fi

if ! which pod >/dev/null; then
  echo "installing cocoapods..."
  gem install cocoapods
else
  echo "cocoapods already installed"
fi

if ! which xcpretty >/dev/null; then
  echo "installing xcpretty."
  gem install xcpretty
else
  echo "xcpretty already installed"
fi

if ! which xctool >/dev/null; then
  echo "installing xctool."
  brew install xctool
else
  echo "xctool already installed"
fi

echo "all dependencies installed."
