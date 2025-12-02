/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The image-dithering app file.
*/

import SwiftUI

@main
struct ImageDitherApp: App {
    
    @StateObject private var imageDitherEngine = ImageDitherEngine()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(imageDitherEngine)
        }
    }
}
