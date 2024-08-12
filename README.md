# SQLiteVec

Swift bindings for [sqlite-vec](https://github.com/asg017/sqlite-vec)

## Installation

### Swift Package Manager

The [Swift Package Manager](https://www.swift.org/documentation/package-manager/) is a tool for managing the distribution of Swift code.

1. Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/jkrukowski/SQLiteVec", from: "0.0.1")
]
```

2. Build your project:

```sh
$ swift build
```

## Usage

```swift
import SQLiteVec

// Initialize the library first
try SQLiteVec.initialize()
```

## Testing

```bash
$ swift test
```
