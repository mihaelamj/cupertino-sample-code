/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The struct that controls the main configuration for the SwiftUI app.
*/

import SwiftUI
public import OSLog

public extension Logger {
    static let app = Logger(subsystem: "com.example.apple-samplecode.WWDC-Sessions", category: "app")
}
    
@main
struct WWDCSessionsApp: App {
    @StateObject private var sessionManager = SessionManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(self.sessionManager)
        }
        #if os(macOS)
        .defaultSize(width: 900, height: 750)
        #endif
    }
}
