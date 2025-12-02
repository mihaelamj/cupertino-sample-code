/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides a list of locations for intent parameters.
*/

import AppIntents
import Foundation
import OSLog

/**
 A `DynamicOptionsProvider` provides a list of valid values for a parameter whose values are unknown until runtime because it has a
 user-configured intent — unlike an `AppEnum`. Use a `DynamicOptionsProvider` when the values for a parameter are a constrained list of
 choices, such as the list of locations in this sample project, rather than an open-ended parameter for any possible location.
 */
struct LocationOptionsProvider: DynamicOptionsProvider {
    
    @Dependency
    private var trailManager: TrailDataManager
    
    func results() async throws -> [String] {
        Logger.intentLogging.debug("Getting locations from LocationOptionsProvider")
        
        // Get a list of locations and return it sorted for display, such as in the Shortcuts app.
        return trailManager.uniqueLocations
                .sorted(using: KeyPathComparator(\.self, comparator: .localizedStandard))
    }
}
