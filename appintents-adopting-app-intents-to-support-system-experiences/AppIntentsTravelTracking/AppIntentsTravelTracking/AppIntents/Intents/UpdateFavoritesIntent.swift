/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent to update the favorite status of a landmark.
*/

import AppIntents

struct UpdateFavoritesIntent: UndoableIntent, Sendable {
    static let title: LocalizedStringResource = "Update Landmark Favorite Status"

    static var parameterSummary: some ParameterSummary {
        Summary("Set \(\.$landmark) to \(\.$isFavorite)")
    }

    @Parameter var landmark: LandmarkEntity
    @Parameter(
        title: "Favorite Status",
        displayName: .init(true: "Favored", false: "Unfavored")
    ) var isFavorite: Bool

    @Dependency var modelData: ModelData

    func perform() async throws -> some IntentResult & ReturnsValue<LandmarkEntity> {
        await modelData.updateFavorite(isFavorite, landmarkEntity: landmark)

        await self.undoManager?.registerUndo(withTarget: modelData) { [isFavorite] modelData in
            modelData.updateFavorite(!isFavorite, landmarkEntity: landmark)
        }

        let actionName: String = if isFavorite {
            String(localized: "Add \(landmark.name) to favorites")
        } else {
            String(localized: "Remove \(landmark.name) from favorites")
        }
        await self.undoManager?.setActionName(actionName)

        return .result(value: landmark)
    }
}

extension UpdateFavoritesIntent {

    init(landmark: LandmarkEntity, isFavorite: Bool) {
        self.landmark = landmark
        self.isFavorite = isFavorite
    }
}
