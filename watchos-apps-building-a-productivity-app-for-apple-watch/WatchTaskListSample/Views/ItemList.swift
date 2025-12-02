/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A list of all the items.
*/

import SwiftUI

struct ItemList: View {
    @EnvironmentObject private var model: ItemListModel
    
    var body: some View {
        List {
            ForEach($model.items) { $item in
                ItemRow(item: $item)
            }
            
            if model.items.isEmpty {
                Text("No items to do!")
                    .foregroundStyle(.gray)
            }
        }
        .toolbar {
            AddItemLink()
        }
        .navigationTitle("Tasks")
    }
}

struct ItemList_Previews: PreviewProvider {
    static var previews: some View {
        ItemList()
            .environmentObject(ItemListModel.shortList)
    }
}
