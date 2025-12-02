/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view modifier for showing sample data in previews.
*/

import SwiftData

@MainActor
let previewContainer: ModelContainer = {
    do {
        let container = try ModelContainer(
            for: Card.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let modelContext = container.mainContext
        if try modelContext.fetch(FetchDescriptor<Card>()).isEmpty {
            SampleDeck.contents.forEach { container.mainContext.insert($0) }
        }
        return container
    } catch {
        fatalError("Failed to create container")
    }
}()
