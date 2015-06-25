deps:
	@pod install

build: deps
	@./scripts/cli/bin/cli build

build-pretty: deps
	@./scripts/cli/bin/cli build | xcpretty -c

test: deps
	@./scripts/cli/bin/cli build test

test-pretty: deps
	@./scripts/cli/bin/cli build test | xcpretty -c

release: deps
	@./scripts/cli/bin/cli release $(version)

.PHONY: deps build test release
