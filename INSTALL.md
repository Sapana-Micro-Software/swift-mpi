# SwiftMPI Installation Guide

**Copyright (C) 2025, Shyamal Suhana Chandra**

This guide provides step-by-step instructions for installing SwiftMPI on various platforms.

## Quick Reference

### macOS (Recommended)
```bash
# Install Xcode from App Store
xcode-select --install
swift --version  # Verify Swift 5.9+
```

### Linux (Ubuntu/Debian)
```bash
sudo apt-get install build-essential libssl-dev
# Download Swift from swift.org
export PATH=/path/to/swift/usr/bin:$PATH
swift --version
```

### Windows
```powershell
# Install WSL2
wsl --install
# Then follow Linux instructions
```

### Add to Your Project
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/Sapana-Micro-Software/swift-mpi.git", from: "1.0.0")
]
```

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [macOS Installation](#macos-installation)
3. [Linux Installation](#linux-installation)
4. [Windows Installation](#windows-installation)
5. [Swift Package Manager](#swift-package-manager)
6. [Xcode Installation](#xcode-installation)
7. [Building from Source](#building-from-source)
8. [Verification](#verification)
9. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- **Swift 5.9 or later**: The Swift programming language compiler
- **Swift Package Manager**: Included with Swift
- **Git**: For cloning the repository (optional)

### System Requirements

- **macOS**: 13.0 (Ventura) or later
- **Linux**: Ubuntu 20.04+, Fedora 35+, or equivalent
- **Windows**: Windows 10/11 with WSL2 or native Swift support

### Platform-Specific Requirements

#### macOS
- Xcode 14.0+ (recommended) or Command Line Tools
- Homebrew (optional, for easy Swift installation)

#### Linux
- Development tools: `build-essential`, `libssl-dev`, `libcurl4-openssl-dev`
- Swift toolchain from [swift.org](https://swift.org/download/)

#### Windows
- Windows Subsystem for Linux (WSL2) with Ubuntu, OR
- Native Swift for Windows (experimental)

## macOS Installation

### Method 1: Using Xcode (Recommended)

1. **Install Xcode**:
   ```bash
   # Download from Mac App Store or
   # https://developer.apple.com/xcode/
   ```

2. **Install Command Line Tools**:
   ```bash
   xcode-select --install
   ```

3. **Verify Swift Installation**:
   ```bash
   swift --version
   ```
   Should show Swift 5.9 or later.

4. **Install SwiftMPI via Swift Package Manager**:
   ```bash
   # Create a new project or add to existing Package.swift
   swift package init --type executable
   ```

### Method 2: Using Homebrew

1. **Install Homebrew** (if not already installed):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Install Swift**:
   ```bash
   brew install swift
   ```

3. **Verify Installation**:
   ```bash
   swift --version
   ```

### Method 3: Direct Swift Toolchain

1. **Download Swift Toolchain**:
   - Visit [swift.org/download](https://swift.org/download/)
   - Download macOS toolchain
   - Extract and add to PATH

2. **Add to PATH**:
   ```bash
   export PATH=/path/to/swift/usr/bin:$PATH
   ```

## Linux Installation

### Ubuntu/Debian

1. **Install Prerequisites**:
   ```bash
   sudo apt-get update
   sudo apt-get install -y \
       build-essential \
       libssl-dev \
       libcurl4-openssl-dev \
       libxml2-dev \
       wget \
       clang
   ```

2. **Install Swift**:
   ```bash
   # Download Swift toolchain
   wget https://swift.org/builds/swift-5.9-release/ubuntu2004/swift-5.9-RELEASE/swift-5.9-RELEASE-ubuntu20.04.tar.gz
   
   # Extract
   tar xzf swift-5.9-RELEASE-ubuntu20.04.tar.gz
   
   # Add to PATH
   export PATH=/path/to/swift-5.9-RELEASE-ubuntu20.04/usr/bin:$PATH
   
   # Make permanent (add to ~/.bashrc)
   echo 'export PATH=/path/to/swift-5.9-RELEASE-ubuntu20.04/usr/bin:$PATH' >> ~/.bashrc
   source ~/.bashrc
   ```

3. **Verify Installation**:
   ```bash
   swift --version
   ```

### Fedora/RHEL/CentOS

1. **Install Prerequisites**:
   ```bash
   sudo dnf install -y \
       gcc \
       gcc-c++ \
       libstdc++-devel \
       libcurl-devel \
       openssl-devel \
       wget \
       clang
   ```

2. **Install Swift**:
   ```bash
   # Download Swift toolchain for your distribution
   wget https://swift.org/builds/swift-5.9-release/centos7/swift-5.9-RELEASE/swift-5.9-RELEASE-centos7.tar.gz
   
   # Extract and add to PATH (similar to Ubuntu)
   ```

### Arch Linux

1. **Install Swift** (using AUR):
   ```bash
   yay -S swift-bin
   # or
   paru -S swift-bin
   ```

2. **Or Install Manually**:
   ```bash
   # Follow similar steps as Ubuntu
   ```

## Windows Installation

### Method 1: Windows Subsystem for Linux (WSL2) - Recommended

1. **Install WSL2**:
   ```powershell
   # In PowerShell as Administrator
   wsl --install
   ```

2. **Install Ubuntu**:
   ```powershell
   wsl --install -d Ubuntu
   ```

3. **Follow Linux Installation Steps**:
   - Open Ubuntu terminal
   - Follow Ubuntu installation instructions above

### Method 2: Native Swift for Windows (Experimental)

1. **Download Swift for Windows**:
   - Visit [swift.org/download](https://swift.org/download/)
   - Download Windows toolchain (if available)

2. **Extract and Add to PATH**:
   ```powershell
   # Add Swift bin directory to system PATH
   ```

## Swift Package Manager

### Adding SwiftMPI to Your Project

#### Method 1: Using Package.swift

1. **Create or Edit Package.swift**:
   ```swift
   // swift-tools-version: 5.9
   import PackageDescription

   let package = Package(
       name: "YourProject",
       dependencies: [
           .package(url: "https://github.com/Sapana-Micro-Software/swift-mpi.git", from: "1.0.0")
       ],
       targets: [
           .target(
               name: "YourProject",
               dependencies: ["SwiftMPI"]
           )
       ]
   )
   ```

2. **Resolve Dependencies**:
   ```bash
   swift package resolve
   ```

3. **Build**:
   ```bash
   swift build
   ```

#### Method 2: Using Xcode

1. **Open Xcode**:
   - File → New → Project
   - Select "macOS" → "Command Line Tool"
   - Choose Swift

2. **Add Package Dependency**:
   - File → Add Packages...
   - Enter repository URL: `https://github.com/Sapana-Micro-Software/swift-mpi.git`
   - Select version and click "Add Package"

3. **Import in Your Code**:
   ```swift
   import SwiftMPI
   ```

#### Method 3: Using Swift Package Manager CLI

1. **Clone Repository** (if installing from source):
   ```bash
   git clone https://github.com/Sapana-Micro-Software/swift-mpi.git
   cd swift-mpi
   ```

2. **Build**:
   ```bash
   swift build
   ```

3. **Run Tests**:
   ```bash
   swift test
   ```

## Xcode Installation

### Setting Up Xcode Project

1. **Create New Project**:
   - Open Xcode
   - File → New → Project
   - Select "macOS" → "Command Line Tool"
   - Name your project

2. **Add Swift Package**:
   - File → Add Packages...
   - Enter: `https://github.com/yourusername/swift-mpi.git`
   - Select version: "Up to Next Major" with "1.0.0"
   - Click "Add Package"

3. **Import Framework**:
   ```swift
   import SwiftMPI
   ```

4. **Build and Run**:
   - Press Cmd+B to build
   - Press Cmd+R to run

## Building from Source

### Prerequisites

- Git
- Swift 5.9+
- Swift Package Manager

### Steps

1. **Clone Repository**:
   ```bash
   git clone https://github.com/Sapana-Micro-Software/swift-mpi.git
   cd swift-mpi
   ```

2. **Build**:
   ```bash
   swift build
   ```

3. **Run Tests**:
   ```bash
   swift test
   ```

4. **Build Documentation** (optional):
   ```bash
   cd docs
   make all
   ```

### Building Release Version

```bash
swift build -c release
```

### Creating Xcode Project

```bash
swift package generate-xcodeproj
```

Then open the generated `.xcodeproj` file in Xcode.

## Verification

### Quick Test

1. **Create Test File** (`test_swiftmpi.swift`):
   ```swift
   import SwiftMPI

   do {
       try SwiftMPI.initialize()
       defer { try? SwiftMPI.finalize() }
       
       let comm = Communicator.world
       let rank = comm.rank()
       let size = comm.size()
       
       print("Hello from process \(rank) of \(size)")
       
       try comm.barrier()
   } catch {
       print("Error: \(error)")
   }
   ```

2. **Compile and Run**:
   ```bash
   swiftc -import-objc-header test_swiftmpi.swift
   ./test_swiftmpi
   ```

### Run Test Suite

```bash
# From project root
swift test

# With verbose output
swift test --verbose

# Run specific test
swift test --filter SwiftMPIXCTests.testInitialization
```

### Verify Installation

```bash
# Check Swift version
swift --version

# Check package resolution
swift package resolve

# Check build
swift build
```

## Troubleshooting

### Common Issues

#### Issue: Swift Not Found

**Solution**:
```bash
# Check if Swift is in PATH
which swift

# Add Swift to PATH (macOS)
export PATH=/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin:$PATH

# Add Swift to PATH (Linux)
export PATH=/path/to/swift/usr/bin:$PATH
```

#### Issue: Package Resolution Fails

**Solution**:
```bash
# Clear package cache
swift package clean
swift package reset

# Try again
swift package resolve
```

#### Issue: Build Errors

**Solution**:
```bash
# Clean build
swift package clean

# Update dependencies
swift package update

# Rebuild
swift build
```

#### Issue: Network Framework Not Available (Linux)

**Solution**:
- Network framework is macOS/iOS specific
- For Linux, you may need to use alternative networking libraries
- Check Swift version compatibility

#### Issue: Permission Denied

**Solution**:
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Check file permissions
ls -la
```

#### Issue: Xcode Command Line Tools Missing

**Solution** (macOS):
```bash
xcode-select --install
sudo xcode-select --switch /Library/Developer/CommandLineTools
```

### Getting Help

1. **Check Documentation**:
   - Read `README.md`
   - Check `docs/` folder

2. **Run Diagnostics**:
   ```bash
   swift --version
   swift package describe
   ```

3. **Report Issues**:
   - Open issue on GitHub
   - Include system information
   - Include error messages
   - Include Swift version

### System Information

To help with troubleshooting, provide:

```bash
# Swift version
swift --version

# System information (macOS)
sw_vers

# System information (Linux)
uname -a
lsb_release -a

# Package information
swift package describe
```

## Next Steps

After successful installation:

1. **Read the README**: `README.md`
2. **Try Examples**: See usage examples in README
3. **Run Tests**: `swift test`
4. **Build Documentation**: `cd docs && make all`
5. **Start Coding**: Import SwiftMPI and begin parallel programming!

## Platform-Specific Notes

### macOS

- Xcode is the recommended development environment
- Network framework is natively available
- Full feature support

### Linux

- Network framework may have limitations
- May require additional system libraries
- Test thoroughly on your distribution

### Windows

- WSL2 is recommended for best compatibility
- Native Windows support is experimental
- Some features may be limited

## Uninstallation

To remove SwiftMPI:

1. **Remove from Package.swift**:
   - Delete dependency line
   - Run `swift package update`

2. **Remove from Xcode**:
   - Select package in project navigator
   - Delete package reference

3. **Clean Build Artifacts**:
   ```bash
   swift package clean
   rm -rf .build
   ```

## Support

For installation issues:

- Check this guide first
- Review README.md
- Open GitHub issue with:
  - Platform and version
  - Swift version
  - Error messages
  - Steps to reproduce

---

**Copyright (C) 2025, Shyamal Suhana Chandra**
