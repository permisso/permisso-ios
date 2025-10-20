// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Permisso",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Permisso",
            targets: ["Permisso"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Permisso",
            path: "Permisso/Sources/Permisso"
        ),
        .testTarget(
            name: "PermissoTests",
            dependencies: ["Permisso"],
            path: "Permisso/Tests/PermissoTests"
        ),
    ]
)
