// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The package for handling the control of a character entity in a RealityKit game.
*/

import PackageDescription

let package = Package(
    name: "CharacterMovement",
    platforms: [.macOS(.v15), .visionOS(.v2), .iOS(.v18), .tvOS("26.0")],
    products: [.library(name: "CharacterMovement", targets: ["CharacterMovement"])],
    targets: [.target(
        name: "CharacterMovement",
        swiftSettings: [.enableUpcomingFeature("MemberImportVisibility")]
    )]
)
