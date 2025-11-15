# Makefile for SwiftMPI Framework
# Copyright (C) 2025, Shyamal Suhana Chandra

.PHONY: build test clean framework xcframework docs

# Build the package
build:
	swift build

# Build in release mode
build-release:
	swift build -c release

# Run tests
test:
	swift test

# Run tests with verbose output
test-verbose:
	swift test --verbose

# Clean build artifacts
clean:
	swift package clean
	rm -rf .build
	rm -rf .swiftpm

# Build framework
framework:
	./scripts/build-framework.sh

# Create XCFramework (template)
xcframework:
	./scripts/create-xcframework.sh

# Generate documentation
docs:
	swift package generate-documentation

# Build and test
all: clean build test

# Framework distribution package
dist: clean build-release test
	@echo "Framework ready for distribution"
	@echo "Version: $$(cat VERSION)"
