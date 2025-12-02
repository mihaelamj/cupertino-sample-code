/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The vImage Pixel Buffer Video Effects app file.
*/


import SwiftUI

@main
struct vImagePixelBufferVideoEffectsApp: App {
    
    @StateObject private var videoEffectsEngine = VideoEffectsEngine()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(videoEffectsEngine)
        }
    }
}
