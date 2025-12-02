/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for the item list.
*/

import Foundation

class ItemListModel: NSObject, ObservableObject {
    @Published var items = [ListItem]()
}

extension ItemListModel {
    
    /// A list model with two items prepopulated for preview and testing.
    static var shortList: ItemListModel {
        let model = ItemListModel()
        model.items.append(contentsOf: [
            ListItem("Brainstorm app ideas"),
            ListItem("Design new app")
        ])
        return model
    }
    
    /// A list model with four items prepopulated for preview and testing.
    static var longList: ItemListModel {
        let model = ItemListModel()
        model.items.append(ListItem("Brainstorm app ideas"))
        model.items.append(ListItem("Design new app"))
        model.items.append(ListItem("Start trademark search"))
        model.items.append(ListItem("Build our story with team"))
        return model
    }
}
