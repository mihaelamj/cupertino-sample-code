/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Accelerate k-means application file.
*/

import SwiftUI

@main
struct AccelerateKMeansApp: App {
    
    @StateObject private var kMeansCalculator = KMeansCalculator()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(kMeansCalculator)
        }
    }
}
