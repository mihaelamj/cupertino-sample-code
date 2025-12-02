/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The house that a bird lives in.
*/

import Foundation

struct BirdHouse: Identifiable {
    var id = UUID()
}

extension BirdHouse {
    static let preview = BirdHouse()
}
