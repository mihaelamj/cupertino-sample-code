/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A button that presents a menu with options to delete one or all quakes.
*/

import SwiftUI
import SwiftData

/// A button that presents a menu with options to delete one or all quakes.
struct DeleteButton: View {
    @Environment(ViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext

    @Query private var quakes: [Quake]
    @Binding var selectedId: Quake.ID?

    var body: some View {
        Menu("Delete", systemImage: "trash") {
            Button {
                guard let selectedQuake = quakes[selectedId] else { return }
                selectedId = nil
                modelContext.delete(selectedQuake)
                viewModel.update(modelContext: modelContext)
            } label: {
                Text("Delete Selected")
            }
            .disabled(selectedId == nil)

            Button {
                selectedId = nil
                try? modelContext.delete(model: Quake.self)
                viewModel.update(modelContext: modelContext)
            } label: {
                Text("Delete All")
            }
        }
        .disabled(quakes.isEmpty)
    }
}

#Preview {
    DeleteButton(selectedId: .constant(nil))
        .environment(ViewModel())
}
