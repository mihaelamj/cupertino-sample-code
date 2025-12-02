// swift-tools-version: 6.2

/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The package that defines the app's server component.
*/

import PackageDescription

let package = Package(
    name: "SKDemoServer",
    defaultLocalization: "en",
    platforms: [
        .iOS("19.0")
    ],
    products: [
        .library(
            name: "SKDemoServer",
            type: .dynamic,
            targets: ["SKDemoServer"]
        )
    ],
    targets: [
        .target(
            name: "SKDemoServer",
            path: ".",
            resources: [.copy("Sources/Products.plist")]
        )
    ]
)
