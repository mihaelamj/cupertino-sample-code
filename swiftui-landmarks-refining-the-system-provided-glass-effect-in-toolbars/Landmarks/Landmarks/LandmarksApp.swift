/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app declaration.
*/

import SwiftUI

/// The main app declaration.
@main
struct LandmarksApp: App {
    /// An object that manages the app's data and state.
    @State private var modelData = ModelData()

    var body: some Scene {
        WindowGroup {
            LandmarksSplitView()
                .environment(modelData)
                .frame(minWidth: 375.0, minHeight: 375.0)
                // Keeps the current window's size for use in scrolling header calculations.
                .onGeometryChange(for: CGSize.self) { geometry in
                    geometry.size
                } action: {
                    modelData.windowSize = $0
                }
        }
    }
}
