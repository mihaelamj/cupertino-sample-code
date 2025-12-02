// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The package for handling WASD input in an application.
*/

import PackageDescription

let package = Package(
    name: "WASDInput",
    platforms: [.macOS(.v15), .visionOS(.v1), .iOS(.v18), .tvOS("26.0")],
    products: [.library(name: "WASDInput", targets: ["WASDInput"])],
    targets: [.target(
        name: "WASDInput",
        swiftSettings: [.enableUpcomingFeature("MemberImportVisibility")]
    )]
)
