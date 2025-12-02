/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app structure.
*/

import SwiftUI

@main
struct AVKitImmersivePlaybackApp: App {
    
    @State private var player = PlayerModel()
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(player)
        }
    }
}
