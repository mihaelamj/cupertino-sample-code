/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Signal extractor from noise application file.
*/

import SwiftUI

@main
struct SignalExtractionFromNoiseApp: App {
    
    @StateObject private var signalExtractor = SignalExtractor()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(signalExtractor)
        }
    }
}
