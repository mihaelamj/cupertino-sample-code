/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent that outputs the details of a trail.
*/

import AppIntents
import Foundation

struct GetTrailInfo: AppIntent {
    
    static let title: LocalizedStringResource = "Get Trail Information"
    static let description = IntentDescription("Provides complete details about a trail, including the current conditions.",
                                               categoryName: "Discover")
    
    /**
     A sentence that describes the intent, incorporating parameters as a natural part of the sentence. The Shortcuts editor displays this sentence
     inline. Without the parameter summary, the Shortcuts editor displays the `trail` parameter as a separate row, making the intent harder to
     configure in a shortcut.
     */
    static var parameterSummary: some ParameterSummary {
        Summary("Get information for \(\.$trail)")
    }

    /**
     The trail this intent gets information for. Either the individual provides this parameter when the intent runs, or it comes preconfigured
     in a shortcut.
     - Tag: parameter
     */
    @Parameter(title: "Trail", description: "The trail to get information for.")
    var trail: TrailEntity
    
    @Dependency
    private var trailManager: TrailDataManager
    
    /// - Tag: custom_response
    func perform() async throws -> some IntentResult & ReturnsValue<TrailEntity> & ProvidesDialog & ShowsSnippetView {
        guard let trailData = trailManager.trail(with: trail.id) else {
            throw TrailIntentError.trailNotFound
        }
                
        /**
         You provide a custom view by conforming the return type of the `perform()` function to the `ShowsSnippetView` protocol.
         */
        let snippet = TrailInfoView(trail: trailData, includeConditions: true)
        
        /**
         This intent displays a custom view that includes the trail conditions as part of the view. The dialog includes the trail conditions when
         the system can only read the response, but not display it. When the system can display the response, the dialog omits the trail
         conditions.
         */
        let dialog = IntentDialog(full: "The latest reported conditions for \(trail.name) indicate: \(trail.currentConditions).",
                                  supporting: "Here's the latest information on trail conditions.")
        
        return .result(value: trail, dialog: dialog, view: snippet)
    }
}
