/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The color-to-grayscale conversion app file.
*/

import SwiftUI

@main
struct GrayscaleConversionApp: App {
    
    @StateObject private var grayscaleConverter = GrayscaleConverter()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(grayscaleConverter)
        }
    }
}
