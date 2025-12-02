/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent to remove a collection from active use.
*/

import AppIntents
import SwiftUI

struct RemoveCollectionIntent: UndoableIntent {

    static let title: LocalizedStringResource = "Remove Collection"

    static var parameterSummary: some ParameterSummary {
        Summary("Remove \(\.$collection) collection")
    }

    @Dependency var modelData: ModelData

    @Parameter(title: "Collection")
    var collection: CollectionEntity

    func perform() async throws -> some IntentResult & ReturnsValue<CollectionEntity?> {
        let archive = Option(title: "Archive", style: .default)
        let delete = Option(title: "Delete", style: .destructive)

        let resultChoice = try await requestChoice(
            between: [.cancel, archive, delete],
            dialog: "Do you want to archive or delete \(collection.name)?",
            view: await collectionSnippetView(collection)
        )

        switch resultChoice {
        case archive: // Archive collection...
            let newCollection = try await modelData.archiveCollection(collection)
            return .result(value: newCollection)
        case delete: // Delete collection...
            await undoManager?.registerUndo(withTarget: modelData) { modelData in
                modelData.restoreCollection(collection)
            }
            await undoManager?.setActionName("Delete \(collection.name)")

            // Delete collection...
            try await modelData.deleteCollection(collection)
            return .result(value: nil)
        default: // Do nothing...
            return .result(value: nil)
        }
    }

    @MainActor
    private func collectionSnippetView(_ collection: CollectionEntity) async -> CollectionSnippetPreview {
        let collection = modelData.collection(id: collection.id)!

        return CollectionSnippetPreview(
            name: collection.name,
            description: collection.description,
            landmarks: collection.landmarks
        )
    }
}
