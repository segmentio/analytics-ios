// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Analytics",
    products: [
        .library(
            name: "Analytics",
            targets: ["Analytics"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Analytics",
            dependencies: [],
            path: "Analytics"),
    ]
)
