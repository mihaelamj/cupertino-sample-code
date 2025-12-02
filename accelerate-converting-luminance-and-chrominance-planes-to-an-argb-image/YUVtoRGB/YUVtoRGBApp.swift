/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The YUV-to-RGB conversion app file.
*/

import SwiftUI

@main
struct YUVtoRGBApp: App {
    
    @StateObject private var converter = YUVtoRGBConverter()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(converter)
        }
    }
}
