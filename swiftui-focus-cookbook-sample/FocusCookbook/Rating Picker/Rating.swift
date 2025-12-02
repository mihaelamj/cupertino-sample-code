/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An enumeration that represents sentiment about an individual recipe.
*/

import SwiftUI

enum Rating: Int, CaseIterable, Identifiable {
    case meh
    case yummy
    case delicious

    var id: RawValue { rawValue }

    var emoji: String {
        switch self {
        case .meh:
            return "😕"
        case .yummy:
            return "🙂"
        case .delicious:
            return "🥰"
        }
    }

    var localizedName: LocalizedStringKey {
        switch self {
        case .meh:
            return "Meh"
        case .yummy:
            return "Yummy"
        case .delicious:
            return "Delicious"
        }
    }

    var previous: Rating? {
        let ratings = Rating.allCases
        let index = ratings.firstIndex(of: self)!

        guard index != ratings.startIndex else {
            return nil
        }

        let previousIndex = ratings.index(before: index)
        return ratings[previousIndex]
    }

    var next: Rating? {
        let ratings = Rating.allCases
        let index = ratings.firstIndex(of: self)!

        let nextIndex = ratings.index(after: index)
        guard nextIndex != ratings.endIndex else {
            return nil
        }

        return ratings[nextIndex]
    }
}
