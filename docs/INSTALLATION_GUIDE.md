# SwiftMPI Installation Guide

**Copyright (C) 2025, Shyamal Suhana Chandra**

> **Note**: This is a reference copy. The main installation guide is located at [INSTALL.md](../INSTALL.md) in the project root.

## Quick Links

- [Main Installation Guide](../INSTALL.md) - Complete installation instructions
- [README](../README.md) - Project overview and usage
- [Paper](paper.tex) - Research paper
- [Presentation](presentation.tex) - Beamer presentation

## Installation Methods

### 1. Swift Package Manager (Recommended)

The easiest way to install SwiftMPI is through Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/Sapana-Micro-Software/swift-mpi.git", from: "1.0.0")
]
```

### 2. Xcode

Add as a package dependency through Xcode's package manager.

### 3. From Source

Clone and build from source:

```bash
git clone https://github.com/Sapana-Micro-Software/swift-mpi.git
cd swift-mpi
swift build
```

## Platform Support

- ✅ **macOS 13.0+**: Full support
- ✅ **Linux**: Full support (Ubuntu, Fedora, etc.)
- ⚠️ **Windows**: Via WSL2 (recommended) or experimental native support

## Requirements

- Swift 5.9 or later
- Swift Package Manager
- No external dependencies (pure Swift implementation)

For detailed platform-specific instructions, troubleshooting, and verification steps, see the [main installation guide](../INSTALL.md).
