/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays an editable list of grocery items.
*/

import SwiftUI

struct GroceryListView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var list: GroceryList
    @FocusState private var currentItemID: GroceryList.Item.ID?

    var body: some View {
        List($list.items) { $item in
            HStack {
                Toggle("Obtained", isOn: $item.isObtained)
                TextField("Item Name", text: $item.name)
                    .onSubmit { addEmptyItem() }
                    .focused($currentItemID, equals: item.id)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                doneButton
            }
            ToolbarItem(placement: .primaryAction) {
                newItemButton
            }
        }
        .defaultFocus($currentItemID, list.items.last?.id)
    }

    // MARK: New item

    private func addEmptyItem() {
        let newItem = list.addItem()
        currentItemID = newItem.id
    }

    private var newItemButton: some View {
        Button {
            addEmptyItem()
        } label: {
            Label("New Item", systemImage: "plus")
        }
    }

    private var doneButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Done")
        }
    }
}

/// The main content view for the Grocery List sheet.
struct GroceryListContentView: View {
    @Binding var list: GroceryList

    var body: some View {
        NavigationStack {
            GroceryListView(list: $list)
                .toggleStyle(.checklist)
                .navigationTitle("Grocery List")
                #if os(macOS)
                .frame(minWidth: 500, minHeight: 400)
                #endif
        }
    }
}
