/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The subject-lifting effects app.
*/

import SwiftUI

/// A main entry point for the app.
@main
struct SubjectLiftingEffectsApp: App {

    /// A pipeline to define as an environment object.
    @StateObject private var pipeline = EffectsPipeline()
    
    /// A scene for the app's main window group.
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(pipeline)
        }
    }
}
