/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A snippet intent that presents a view that displays a landmark.
*/

import AppIntents
import SwiftUI

struct LandmarkSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Landmark Snippet"

    @Parameter var landmark: LandmarkEntity
    @Dependency var modelData: ModelData

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let isFavorite = await modelData.isFavorite(landmark)

        return .result(
            view: LandmarkView(landmark: landmark, isFavorite: isFavorite)
        )
    }
}

extension LandmarkSnippetIntent {
    init(landmark: LandmarkEntity) {
        self.landmark = landmark
    }
}

