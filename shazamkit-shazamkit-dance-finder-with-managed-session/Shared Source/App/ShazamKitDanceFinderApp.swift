/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI scene builder that sets up the UI for the ShazamKitDanceFinder app.
*/

import SwiftUI

@main
struct ShazamKitDanceFinderApp: App {
    
    @StateObject private var matcher = Matcher()
    @StateObject private var sceneHandler = SceneHandler()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(matcher)
                .environmentObject(sceneHandler)
                .onChange(of: scenePhase) { _, newScenePhase in
                    sceneHandler.sceneChanged(to: newScenePhase)
                }
        }
    }
}

@MainActor final class SceneHandler: ObservableObject {
    
    enum State {
        case foreground
        case background
    }
    
    private(set) var state: State = .foreground
    
    func sceneChanged(to newScenePhase: ScenePhase) {
        
        // Only handle the active and background states for the subviews.
        guard newScenePhase != .inactive else { return }
        
        state = newScenePhase == .background ? .background : .foreground
    }
}
