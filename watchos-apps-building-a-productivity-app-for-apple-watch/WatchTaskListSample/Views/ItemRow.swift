/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to display a list item as a row in the list.
*/

import SwiftUI

struct ItemRow: View {
    @EnvironmentObject private var model: ItemListModel
    
    @Binding var item: ListItem
    @State private var showDetail = false
    
    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack {
                Text(item.description)
                    .strikethrough(item.isComplete)
                Spacer()
                Image(systemName: "checkmark").opacity(item.isComplete ? 100 : 0)
            }
        }
        .sheet(isPresented: $showDetail) {
            ItemDetail(item: $item)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showDetail = false
                        }
                    }
                }
        }
    }
}

struct ItemRow_Previews: PreviewProvider {
    static var previews: some View {
        ItemRow(item: .constant(ListItem("Build an app!")))
            .environmentObject(ItemListModel())
    }
}
