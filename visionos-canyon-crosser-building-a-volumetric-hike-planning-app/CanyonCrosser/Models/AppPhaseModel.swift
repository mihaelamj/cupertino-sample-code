/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model to switch between views.
*/

import SwiftUI

@Observable
final class AppPhaseModel {
    /// An enumeration of the different phases of the app.
    enum AppPhase: Sendable, Equatable {
        /// Loading assets from Reality Composer Pro before the app starts.
        case loadingAssets

        /// Choosing a landmark from the carousel.
        case carousel

        /// In the main app view, the Grand Canyon.
        case grandCanyon
    }
    
    // Start the app by loading assets.
    var appPhase: AppPhase = .loadingAssets
}
