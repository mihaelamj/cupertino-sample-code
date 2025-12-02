/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A text field link to add an item to the item list model.
*/

import SwiftUI

struct AddItemLink: View {
    @EnvironmentObject private var model: ItemListModel
    
    var body: some View {
        VStack {
            TextFieldLink(prompt: Text("New Item")) {
                Label("Add",
                      systemImage: "plus.circle.fill")
            } onSubmit: {
                model.items.append(ListItem($0))
            }
            
            Spacer()
                .frame(height: 5.0)
        }
    }
}

struct AddItemLink_Previews: PreviewProvider {
    static var previews: some View {
        AddItemLink()
            .environmentObject(ItemListModel())
    }
}
