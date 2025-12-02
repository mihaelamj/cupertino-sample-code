/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main entry point to the app.
*/

import SwiftUI

@main
struct SignalGeneratorApp: App {
    @State private var audioManager = AudioManager()
    
    var body: some Scene {
        WindowGroup {
            // Set the frame size explicitly on macOS.
            ContentView(audioManager: $audioManager)
#if os(macOS)
                .frame(minWidth: 600, minHeight: 300)
#endif
        }
    }
}
