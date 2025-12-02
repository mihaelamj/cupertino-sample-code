/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Model object for populating content in a table view or collection view.
*/

import UIKit

struct Model: Hashable {
    
    let name: String
    let identifier = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
 
    static func createItem(index: Int) -> Model {
        return Model(name: "image" + "\(index + 1)")
    }

}
