XCPRETTY := xcpretty -c && exit ${PIPESTATUS[0]}

SDK ?= "iphonesimulator"
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
	xcodebuild test $(XC_ARGS) | $(XCPRETTY)

xcbuild:
	xctool $(XC_ARGS)

xctest:
	xctool test $(XC_ARGS)

.PHONY: test build clean
.SILENT:
