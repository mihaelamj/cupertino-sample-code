/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A sample app that shows how to use Continuity Camera in macOS.
*/

import SwiftUI

@main
struct ContinuityCamApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .navigationTitle("Continuity Camera Sample")
                .frame(minWidth: 800, minHeight: 600)
        }
    }
}
