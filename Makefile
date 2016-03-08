XCPRETTY := xcpretty -c && exit ${PIPESTATUS[0]}

SDK ?= "iphonesimulator"
DESTINATION ?= "platform=iOS Simulator,name=iPhone 5"
PROJECT := Analytics
XC_ARGS := -scheme $(PROJECT)-Example -workspace Example/$(PROJECT).xcworkspace -sdk $(SDK) -destination $(DESTINATION) ONLY_ACTIVE_ARCH=NO

bootstrap:
	.buildscript/bootstrap.sh

install: Example/Podfile Analytics.podspec
	pod install --project-directory=Example

clean:
	xcodebuild $(XC_ARGS) clean | $(XCPRETTY)

build:
	xcodebuild $(XC_ARGS) | $(XCPRETTY)

test:
	xcodebuild test $(XC_ARGS) | $(XCPRETTY)

xcbuild:
	xctool $(XC_ARGS)

xctest:
	xctool test $(XC_ARGS)

.PHONY: bootstrap test xctest build xcbuild clean
.SILENT:
