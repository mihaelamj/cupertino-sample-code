/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that creates a model container before showing preview content.
*/

import SwiftUI
import SwiftData

/// A view that creates a model container before showing preview content.
///
/// Use this view type only for previews, and only when you need
/// to create a container before showing the view content. As an example
/// of how to use this view, see the preview for `QuakeRow`.
struct ModelContainerPreview<Content: View>: View {
    var content: () -> Content
    let container: ModelContainer

    /// Creates a view that creates the specified model container before
    /// displaying the preview content.
    init(
        _ modelContainer: @escaping () throws -> ModelContainer,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
        do {
            self.container = try MainActor.assumeIsolated(modelContainer)
        } catch {
            fatalError("Failed to create the model container: \(error.localizedDescription)")
        }
    }

    var body: some View {
        content()
            .modelContainer(container)
    }
}
