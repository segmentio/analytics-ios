SDK ?= "iphonesimulator"
DESTINATION ?= "platform=iOS Simulator,name=iPhone X"
PROJECT := Analytics
XC_ARGS := -workspace $(PROJECT).xcworkspace -scheme $(PROJECT) -destination $(DESTINATION) GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES
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

clean:
	xcodebuild $(XC_ARGS) clean

build:
	xcodebuild $(XC_ARGS) $(XC_BUILD_ARGS)

test:
	xcodebuild test $(XC_ARGS) $(XC_TEST_ARGS)

clean-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) clean | xcpretty

build-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) $(XC_BUILD_ARGS) | xcpretty

test-pretty:
	@set -o pipefail && xcodebuild test $(XC_ARGS) $(XC_TEST_ARGS) | xcpretty --report junit

xctest:
	xctool $(XC_ARGS) run-tests

.PHONY: bootstrap dependencies lint carthage archive build test xctest clean
