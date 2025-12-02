/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app file for the biquadratic coefficients calculator.
*/

import SwiftUI
import Accelerate

@main
struct BiquadCoefficientsCalculatorApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    
    // The `musicProvider` object provides the music loop and exposes an API
    // to filter the music loop using a biquadratic filter.
    let musicProvider = FilterableMusicProvider()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(musicProvider)
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        Task(priority: .userInitiated) {
                            try? await musicProvider.loadAudioSamples()
                            try? SignalGenerator(signalProvider: musicProvider).start()
                        }
                    }
                }
        }
    }
}
