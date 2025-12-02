/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The sky compositor app file.
*/

import SwiftUI


@main
struct vImageSkyCompositorApp: App {

    @StateObject private var imageProvider = ImageProvider()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(imageProvider)
        }
    }
    
}
