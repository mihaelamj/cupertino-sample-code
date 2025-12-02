/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The custom resampling app file.
*/

import SwiftUI

@main
struct CustomResamplingApp: App {
    
    @StateObject private var customResamplingEngine = CustomResamplingEngine()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(customResamplingEngine)
        }
    }
}
