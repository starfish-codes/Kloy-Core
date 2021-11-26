default: lint

lint:
	@swift run swiftformat --lint --swiftversion 5.5 .
