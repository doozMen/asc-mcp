// swift-tools-version:6.0
import PackageDescription

let package = Package(
  name: "asc-mcp",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "asc", targets: ["asc-mcp"])
  ],
  dependencies: [
    .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.9.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    .package(url: "https://github.com/aaronsky/asc-swift.git", from: "1.0.0"),
    .package(url: "https://github.com/swiftlang/swift-subprocess.git", from: "0.1.1"),
  ],
  targets: [
    .executableTarget(
      name: "asc-mcp",
      dependencies: [
        .product(name: "MCP", package: "swift-sdk"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "AppStoreConnect", package: "asc-swift"),
        .product(name: "Subprocess", package: "swift-subprocess"),
      ]
    ),
    .testTarget(
      name: "asc-mcp-tests",
      dependencies: ["asc-mcp"]
    ),
  ]
)
