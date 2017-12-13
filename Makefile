SDK ?= "iphonesimulator"
DESTINATION ?= "platform=iOS Simulator,name=iPhone 7"
PROJECT := Analytics
XC_ARGS := -scheme $(PROJECT) -workspace $(PROJECT).xcworkspace -sdk $(SDK) -destination $(DESTINATION) ONLY_ACTIVE_ARCH=NO GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES

bootstrap:
	.buildscript/bootstrap.sh

install: Podfile Analytics.podspec
	pod install

lint:
	pod lib lint

carthage:
	carthage build --no-skip-current

archive: carthage
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
	set -o pipefail && xcodebuild test $(XC_ARGS) | xcpretty --report junit

xcbuild:
	xctool $(XC_ARGS)

xctest:
	xctool test $(XC_ARGS)

.PHONY: bootstrap lint carthage archive test xctest build xcbuild clean
