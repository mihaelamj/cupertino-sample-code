/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app file for the DCT audio equalization app.
*/

import SwiftUI

@main
struct AudioEqualizationApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    
    // The `drumLoopProvider` object provides the drum loop and exposes an API
    // to apply audio equalization.
    let drumLoopProvider = DrumLoopProvider()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(drumLoopProvider)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Task(priority: .userInitiated) {
                    try? await drumLoopProvider.loadAudioSamples()
                    try? SignalGenerator(signalProvider: drumLoopProvider).start()
                }
            }
        }
    }
}
