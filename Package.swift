// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SQLiteVec",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "SQLiteVecCLI",
            targets: ["SQLiteVecCLI"]
        ),
        .library(
            name: "SQLiteVec",
            targets: ["SQLiteVec"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "SQLiteVecCLI",
            dependencies: [
                "SQLiteVec",
            ]
        ),
        .target(
            name: "SQLiteVec",
            dependencies: [
                "CSQLiteVec",
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .target(
            name: "CSQLiteVec",
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "SQLiteVecTests",
            dependencies: [
                "SQLiteVec",
            ]
        ),
    ]
)
