/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A utility that adds app entities to the Spotlight index.
*/

import AppIntents
import CoreSpotlight

enum EntityDonator {
    static func donateLandmarks(modelData: ModelData) async throws {
        let landmarkEntities = await modelData.landmarkEntities
        try await CSSearchableIndex.default().indexAppEntities(landmarkEntities)
    }
}
