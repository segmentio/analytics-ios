SDK ?= "iphonesimulator"
DESTINATION ?= "platform=iOS Simulator,OS=10.0,name=iPhone 7"
PROJECT := Analytics
XC_ARGS := -scheme $(PROJECT)-Example -workspace Example/$(PROJECT).xcworkspace -sdk $(SDK) -destination $(DESTINATION) ONLY_ACTIVE_ARCH=NO

bootstrap:
	.buildscript/bootstrap.sh

install: Example/Podfile Analytics.podspec
	pod install --project-directory=Example

lint:
	pod lib lint

carthage:
	carthage build --no-skip-current

archive:
	carthage archive Analytics

clean:
	xcodebuild $(XC_ARGS) clean

build:
	xcodebuild $(XC_ARGS)

test:
	xcodebuild test $(XC_ARGS)

clean-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) clean | xcpretty

build-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) | xcpretty

test-pretty:
	set -o pipefail && xcodebuild test $(XC_ARGS) | xcpretty

xcbuild:
	xctool $(XC_ARGS)

xctest:
	xctool test $(XC_ARGS)

.PHONY: bootstrap lint carthage archive test xctest build xcbuild clean
