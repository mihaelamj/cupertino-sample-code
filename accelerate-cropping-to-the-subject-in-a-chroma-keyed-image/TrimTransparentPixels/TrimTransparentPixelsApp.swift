/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The trim transparent pixels app file.
*/

import SwiftUI

@main
struct TrimTransparentPixelsApp: App {
    @StateObject private var imageProvider = ImageProvider()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(imageProvider)
        }
    }
}
