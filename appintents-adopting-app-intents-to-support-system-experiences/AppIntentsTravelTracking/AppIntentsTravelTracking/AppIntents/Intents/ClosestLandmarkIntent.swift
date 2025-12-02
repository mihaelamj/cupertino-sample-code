/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent to find the closest landmark.
*/

import AppIntents
import SwiftUI

struct ClosestLandmarkIntent: AppIntent {
    static let title: LocalizedStringResource = "Find Closest Landmark"

    @Dependency var modelData: ModelData

    func perform() async throws -> some ReturnsValue<LandmarkEntity> & ShowsSnippetIntent & ProvidesDialog {
        let landmark = await self.findClosestLandmark()

        return .result(
            value: landmark,
            dialog: IntentDialog(
                full: "The closest landmark is \(landmark.name).",
                supporting: "\(landmark.name) is located in \(landmark.continent)."
            ),
            snippetIntent: LandmarkSnippetIntent(landmark: landmark)
        )
    }
}

private extension ClosestLandmarkIntent {
    private func findClosestLandmark() async -> LandmarkEntity {
        // The sample app always returns the same app entity to keep it focused on
        // functionality provided by the App Intents framework.
        // In your app, you might perform a location lookup with CoreLocation,
        // search your database, and so on, to find the landmark that's closest
        // to the person.
        return await LandmarkEntity(
            landmark: modelData.landmarksById[1005]!,
            modelData: modelData,
        )
    }
}

