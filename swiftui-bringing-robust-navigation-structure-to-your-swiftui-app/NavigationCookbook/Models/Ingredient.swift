/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data model for an ingredient for a given recipe.
*/

import SwiftUI

/// A data model for an ingredient for a given recipe.
struct Ingredient: CustomStringConvertible, Decodable, Hashable, Identifiable {
    private(set) var id = UUID()
    private(set) var description: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        description = try container.decode(String.self)
    }
}
