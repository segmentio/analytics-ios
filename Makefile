test:
	@./scripts/cli/bin/cli build test

release:
	@./scripts/cli/bin/cli release $(version)
