// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Implementations",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Implementations",
            targets: ["Implementations"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/leviouwendijk/plate.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Structures.git",
            branch: "master"
        ),
        // .package(
        //     url: "https://github.com/leviouwendijk/ViewComponents.git",
        //     branch: "master"
        // ),
        .package(
            url: "https://github.com/leviouwendijk/Interfaces.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Economics.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Commerce.git",
            branch: "master"
        ),

        .package(
            url: "https://github.com/leviouwendijk/Version.git",
            branch: "master"
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Implementations",
            dependencies: [
                .product(name: "plate", package: "plate"),
                .product(name: "Structures", package: "Structures"),
                // .product(name: "ViewComponents", package: "ViewComponents"),
                .product(name: "Interfaces", package: "Interfaces"),
                .product(name: "Economics", package: "Economics"),
                .product(name: "Commerce", package: "Commerce"),
                .product(name: "Version", package: "Version"),
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ImplementationsTests",
            dependencies: [
                "Implementations",
                .product(name: "plate", package: "plate"),
                // .product(name: "ViewComponents", package: "ViewComponents"),
                .product(name: "Interfaces", package: "Interfaces"),
                .product(name: "Economics", package: "Economics"),
                .product(name: "Structures", package: "Structures"),
                .product(name: "Commerce", package: "Commerce"),
            ]
        ),
    ]
)
