/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that provides a sample set of color data.
*/

import UIKit

class ColorData {

    /// An initial set of colors.

    var colors = [
        ColorItem(name: "Red", color: #colorLiteral(red: 1, green: 0.231_372_549, blue: 0.188_235_294_1, alpha: 1), starred: false),
        ColorItem(name: "Orange", color: #colorLiteral(red: 1, green: 0.584_313_725_5, blue: 0, alpha: 1), starred: false),
        ColorItem(name: "Yellow", color: #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1), starred: false),
        ColorItem(name: "Green", color: #colorLiteral(red: 0.298_039_215_7, green: 0.850_980_392_2, blue: 0.392_156_862_7, alpha: 1), starred: false),
        ColorItem(name: "Teal Blue", color: #colorLiteral(red: 0.352_941_176_5, green: 0.784_313_725_5, blue: 0.980_392_156_9, alpha: 1), starred: false),
        ColorItem(name: "Blue", color: #colorLiteral(red: 0, green: 0.478_431_372_5, blue: 1, alpha: 1), starred: false),
        ColorItem(name: "Purple", color: #colorLiteral(red: 0.345_098_039_2, green: 0.337_254_902, blue: 0.839_215_686_3, alpha: 1), starred: false),
        ColorItem(name: "Pink", color: #colorLiteral(red: 1, green: 0.176_470_588_2, blue: 0.333_333_333_3, alpha: 1), starred: false)
    ]

    /// Delete a ColorItem object from the set of colors.

    func delete(_ colorItem: ColorItem) {
        guard let arrayIndex = colors.firstIndex(of: colorItem)
            else { preconditionFailure("Expected colorItem to exist in colors") }

        colors.remove(at: arrayIndex)

        // Send a notifications so that UI can be updated and pass the index where the colorItem was removed from.
        NotificationCenter.default.post(name: .colorItemDeleted, object: self, userInfo: [ "index": arrayIndex ])
    }

}
