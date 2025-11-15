#!/bin/bash
# Build SwiftMPI as a framework
# Copyright (C) 2025, Shyamal Suhana Chandra

set -e

FRAMEWORK_NAME="SwiftMPI"
BUILD_DIR=".build"
FRAMEWORK_DIR="$BUILD_DIR/framework"

echo "Building $FRAMEWORK_NAME framework..."

# Clean previous builds
rm -rf "$BUILD_DIR"
rm -rf "$FRAMEWORK_DIR"

# Build for macOS
echo "Building for macOS..."
swift build -c release --arch arm64 --arch x86_64

# Create framework structure
mkdir -p "$FRAMEWORK_DIR/$FRAMEWORK_NAME.framework/Modules"
mkdir -p "$FRAMEWORK_DIR/$FRAMEWORK_NAME.framework/Headers"

# Copy module files
if [ -d "$BUILD_DIR/release" ]; then
    find "$BUILD_DIR/release" -name "*.swiftmodule" -exec cp -R {} "$FRAMEWORK_DIR/$FRAMEWORK_NAME.framework/Modules/" \;
fi

echo "Framework build complete!"
echo "Framework location: $FRAMEWORK_DIR/$FRAMEWORK_NAME.framework"
