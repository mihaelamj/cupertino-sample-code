/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The histogram specification app file.
*/

import SwiftUI

@main
struct HistogramSpecificationApp: App {
    
    @StateObject private var histogramSpecifier = HistogramSpecifier()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(histogramSpecifier)
        }
    }
}
