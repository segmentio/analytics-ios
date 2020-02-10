SDK ?= "iphonesimulator"
IOS_DESTINATION := "platform=iOS Simulator,name=iPhone X"
TVOS_DESTINATION := "platform=tvOS Simulator,name=Apple TV"
XC_ARGS := -workspace Analytics.xcworkspace GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES
IOS_XCARGS := $(XC_ARGS) -destination $(IOS_DESTINATION) -scheme AnalyticsTests
TVOS_XCARGS := $(XC_ARGS) -destination $(TVOS_DESTINATION) -scheme AnalyticsTestsTVOS
XC_BUILD_ARGS := ONLY_ACTIVE_ARCH=NO
XC_TEST_ARGS := GCC_GENERATE_TEST_COVERAGE_FILES=YES RUN_E2E_TESTS=$(RUN_E2E_TESTS) WEBHOOK_AUTH_USERNAME=$(WEBHOOK_AUTH_USERNAME)

bootstrap:
	.buildscript/bootstrap.sh

dependencies: Podfile Analytics.podspec
	pod install

lint:
	pod lib lint --allow-warnings

carthage:
	carthage build --no-skip-current

archive: carthage
	carthage archive Analytics

clean-ios:
	set -o pipefail && xcodebuild $(IOS_XCARGS) clean | xcpretty

clean-tvos:
	set -o pipefail && xcodebuild $(TVOS_XCARGS) clean | xcpretty

clean: clean-ios clean-tvos

build-ios:
	set -o pipefail && xcodebuild $(IOS_XCARGS) $(XC_BUILD_ARGS) | xcpretty

build-tvos:
	set -o pipefail && xcodebuild $(TVOS_XCARGS) $(XC_BUILD_ARGS) | xcpretty

build: build-ios build-tvos

test-tvos:
	@set -o pipefail && xcodebuild test $(TVOS_XCARGS) $(XC_TEST_ARGS) | xcpretty --report junit

test-ios:
	@set -o pipefail && xcodebuild test $(IOS_XCARGS) $(XC_TEST_ARGS) | xcpretty --report junit

test: test-ios test-tvos

xctest:
	xctool $(IOS_XCARGS) run-tests -sdk iphonesimulator

.PHONY: bootstrap dependencies lint carthage archive build test xctest clean
