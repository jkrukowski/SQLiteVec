// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SQLiteVec",
    platforms: [
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
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
        .library(
            name: "CSQLiteVec",
            targets: ["CSQLiteVec"]
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
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags(["-w"]),
            ]
        ),
        .testTarget(
            name: "SQLiteVecTests",
            dependencies: [
                "SQLiteVec",
            ]
        ),
    ]
)
