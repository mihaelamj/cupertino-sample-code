/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An enumeration that represents a search token.
*/

enum SearchToken: String, Identifiable {

    var id: String { rawValue }

    case image
}
