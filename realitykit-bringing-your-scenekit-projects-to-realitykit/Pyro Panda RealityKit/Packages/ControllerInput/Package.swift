// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The package for handling the input of a game controller and passing the data to RealityKit entities.
*/

import PackageDescription

let package = Package(
    name: "ControllerInput",
    platforms: [.macOS(.v15), .visionOS(.v1), .iOS(.v18), .tvOS("26.0")],
    products: [
        .library(name: "ControllerInput", targets: ["ControllerInput"]),
        .library(name: "HapticUtility", targets: ["HapticUtility"])
    ],
    targets: [
        .target(
            name: "ControllerInput",
            dependencies: [.target(name: "HapticUtility")],
            swiftSettings: [.enableUpcomingFeature("MemberImportVisibility")]
        ),
        .target(
            name: "HapticUtility",
            swiftSettings: [.enableUpcomingFeature("MemberImportVisibility")]
        )
    ]
)
