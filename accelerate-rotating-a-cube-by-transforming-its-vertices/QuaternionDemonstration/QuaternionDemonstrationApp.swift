/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The cube rotation application file.
*/

import SwiftUI
import SceneKit

@main
struct QuaternionDemonstrationApp: App {
    
    @StateObject private var cubeRotation = CubeRotation()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cubeRotation)
        }
    }
}
