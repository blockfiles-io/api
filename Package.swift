// swift-tools-version:5.2
import PackageDescription

let packageName = "blockfiles"
let appLibraryName = "\(packageName)Impl"
let executableName = "Run"

let package = Package(
    name: packageName,
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: appLibraryName, targets: [appLibraryName]),
        .executable(name: executableName, targets: [executableName]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0"),
        .package(url: "https://github.com/skelpo/vapor-aws-lambda-runtime.git", from: "0.7.2"),
        .package(url: "https://github.com/soto-project/soto.git", .exact("6.5.0")),
        .package(url: "https://github.com/soto-project/soto-core.git", .exact("6.4.1")),
        .package(url: "https://github.com/Boilertalk/Web3.swift.git", from: "0.6.0"),
    ],
    targets: [
        .target(name: appLibraryName,
                dependencies: [
                    .product(name: "Vapor", package: "vapor"),
                    .product(name: "Fluent", package: "fluent"),
                    .product(name: "FluentMySQLDriver", package: "fluent-mysql-driver"),
                    .product(name: "SotoS3", package: "soto"),
                    .product(name: "Web3", package: "Web3.swift"),
                    .product(name: "Web3ContractABI", package: "Web3.swift"),
                    .product(name: "SotoSignerV4", package: "soto-core"),
                ],
                path: "Sources/App"),
        .target(name: executableName,
                dependencies: [
                    .byName(name: appLibraryName),
                    .product(name: "VaporAWSLambdaRuntime", package: "vapor-aws-lambda-runtime"),
                ],
                path: "Sources/Run"),
        .testTarget(name: "\(appLibraryName)Tests",
                    dependencies: [.target(name: appLibraryName)],
                    path: "Tests/AppTests"),
    ]
)
