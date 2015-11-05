XCPRETTY := xcpretty -c && exit ${PIPESTATUS[0]}

SDK ?= "iphonesimulator9.1"
DESTINATION ?= "platform=iOS Simulator,name=iPhone 5"
PROJECT := Analytics
XC_ARGS := -scheme $(PROJECT)-Example -workspace Example/$(PROJECT).xcworkspace -sdk $(SDK) -destination $(DESTINATION) ONLY_ACTIVE_ARCH=NO

install: Podfile
	pod install

clean:
	xcodebuild $(XC_ARGS) clean | $(XCPRETTY)

build:
	xcodebuild $(XC_ARGS) | $(XCPRETTY)

test:
	xcodebuild $(XC_ARGS) test | $(XCPRETTY)

xcbuild:
	xctool $(XC_ARGS)

xctest:
	xctool $(XC_ARGS) test

.PHONY: test build clean
.SILENT:
