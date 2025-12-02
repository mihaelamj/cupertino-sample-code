/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry point for the app.
*/

import SwiftUI
import WiFiAware
import OSLog

let logger = Logger(subsystem: "com.example.apple-samplecode.Wi-FiAwareSample", category: "App")

@main
struct WiFiAwareSampleApp: App {
    var body: some Scene {
        WindowGroup {
            if WACapabilities.supportedFeatures.contains(.wifiAware) {
                ContentView()
            } else {
                ContentUnavailableView {
                    Label("This device does not support Wi-Fi Aware", systemImage: "exclamationmark.octagon")
                }
            }
        }
    }
}
