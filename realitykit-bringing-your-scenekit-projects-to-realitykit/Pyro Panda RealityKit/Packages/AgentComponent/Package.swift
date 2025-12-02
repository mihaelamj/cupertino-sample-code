// swift-tools-version: 6.0
/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The package for handling the control of agents in a RealityKit app.
*/

import PackageDescription

let package = Package(
    name: "AgentComponent",
    platforms: [.iOS(.v18), .macOS(.v15), .visionOS(.v1), .tvOS("26.0")],
    products: [.library(name: "AgentComponent", targets: ["AgentComponent"])],
    targets: [.target(
        name: "AgentComponent",
        swiftSettings: [.enableUpcomingFeature("MemberImportVisibility")]
    )]
)
