/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Gamma Correction app file.
*/
import SwiftUI

@main
struct GammaCorrectionApp: App {
    
    @StateObject private var gammaCorrectionEngine = GammaCorrectionEngine()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gammaCorrectionEngine)
        }
    }
}
