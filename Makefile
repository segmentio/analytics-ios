deps:
	@pod install

build: deps
	@./scripts/cli/bin/cli build

test: deps
	@./scripts/cli/bin/cli build test

release: deps
	@./scripts/cli/bin/cli release $(version)

.PHONY: deps build test release
