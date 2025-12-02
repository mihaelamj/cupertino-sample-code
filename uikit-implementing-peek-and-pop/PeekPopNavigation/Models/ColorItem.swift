/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model class used to represent starred and unstarred colors.
*/

import UIKit

class ColorItem {

    var name: String {
        didSet {
            NotificationCenter.default.post(name: .colorItemUpdated, object: self)
        }
    }

    var color: UIColor {
        didSet {
            NotificationCenter.default.post(name: .colorItemUpdated, object: self)
        }
    }

    var starred: Bool {
        didSet {
            NotificationCenter.default.post(name: .colorItemUpdated, object: self)
        }
    }

    // MARK: - Object life cycle

    init(name: String, color: UIColor, starred: Bool) {
        self.name = name
        self.color = color
        self.starred = starred
    }

}

/// Extends ColorItem to be equatable.

extension ColorItem: Equatable {

    static func == (lhs: ColorItem, rhs: ColorItem) -> Bool {
        return lhs.name == rhs.name && lhs.color == rhs.color && lhs.starred == rhs.starred
    }

}
