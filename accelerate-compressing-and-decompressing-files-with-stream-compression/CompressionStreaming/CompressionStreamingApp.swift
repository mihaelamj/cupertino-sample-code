/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The file compressor app file.
*/

import SwiftUI

@main
struct CompressionStreamingApp: App {
    
    @StateObject private var compressor = Compressor()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(compressor)
        }
    }
}
