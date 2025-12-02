/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app structure.
*/

import SwiftUI

@main
struct MultiviewVideoPlaybackApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: CustomApplicationDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1200, minHeight: 600)
        }
        .windowResizability(.contentSize)
    }
}
