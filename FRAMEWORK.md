# SwiftMPI Framework

## Framework Distribution

SwiftMPI is distributed as a dynamic Swift framework that can be integrated into your projects using Swift Package Manager.

## Installation

### Swift Package Manager

Add SwiftMPI to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Sapana-Micro-Software/swift-mpi.git", from: "1.0.0")
]
```

Or add it via Xcode:
1. File → Add Packages...
2. Enter the repository URL
3. Select version and add to your target

### Framework Type

SwiftMPI is configured as a **dynamic library** for optimal framework distribution:
- Enables dynamic linking at runtime
- Supports framework embedding in applications
- Allows for framework updates without recompiling dependent code

## Framework Structure

```
SwiftMPI.framework/
├── SwiftMPI (binary)
├── Headers/
│   └── SwiftMPI-Swift.h (generated)
├── Modules/
│   └── SwiftMPI.swiftmodule/
│       ├── x86_64-apple-macosx.swiftmodule
│       ├── arm64-apple-macosx.swiftmodule
│       └── ...
└── Info.plist
```

## Usage in Your Project

### Import the Framework

```swift
import SwiftMPI
```

### Basic Usage

```swift
// Initialize MPI
try SwiftMPI.initialize()
defer { try? SwiftMPI.finalize() }

// Get world communicator
let comm = SwiftMPI.world

// Use MPI operations
let rank = comm.rank()
let size = comm.size()
print("Hello from process \(rank) of \(size)")
```

## Framework Requirements

- **Minimum Deployment Targets:**
  - macOS 13.0+
  - iOS 16.0+
  - tvOS 16.0+
  - watchOS 9.0+

- **Swift Version:** 5.9 or later

## Building the Framework

### Using Swift Package Manager

```bash
swift build -c release
```

### Creating Xcode Framework

1. Open the package in Xcode
2. Select the SwiftMPI scheme
3. Product → Archive
4. Export the framework

## Framework Distribution

The framework can be distributed as:
- Swift Package (recommended)
- XCFramework bundle
- Dynamic framework binary

## Integration with Xcode Projects

1. Add SwiftMPI as a package dependency
2. Link the framework to your target
3. Import and use in your code

## Version Information

Current version: 1.0.0

See `VERSION` file for version details.
