/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent that opens the app and navigates to the Favorites trail collection.
*/

import Foundation
import AppIntents

/**
 People are likely to visit the Favorites trail collection often, so this intent makes it quicker and more convenient to open the app to that content.
 
 - Tag: open_favorites_intent
 */
struct OpenFavorites: AppIntent {
    
    /// Each intent needs to include metadata, such as a localized title. The title of the intent displays throughout the system.
    static let title: LocalizedStringResource = "Open Favorite Trails"

    /// An intent can optionally provide a localized description that the Shortcuts app displays.
    static let description = IntentDescription("Opens the app and goes to your favorite trails.")
    
    /// Tell the system to bring the app to the foreground when the intent runs.
    static let openAppWhenRun: Bool = true
    
    /**
     When the system runs the intent, it calls `perform()`.
     
     Intents run on an arbitrary queue. Intents that manipulate UI need to annotate `perform()` with `@MainActor`
     so that the UI operations run on the main actor.
     */
    @MainActor
    func perform() async throws -> some IntentResult {
        navigationModel.selectedCollection = trailManager.favoritesCollection
        
        /// Return an empty result, indicating that the intent is complete.
        return .result()
    }
    
    /**
     The app uses the navigation model to update the UI to the individual's favorite trail.
     The `@Dependency` property wrapper sets up the specific navigation model to use, which the app provides
     during its launch. See `AppIntentsSampleApp` to observe where the app creates the dependency.
     */
    @Dependency
    private var navigationModel: NavigationModel
    
    @Dependency
    private var trailManager: TrailDataManager
}
