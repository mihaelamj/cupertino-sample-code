/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A book data model.
*/

import SwiftUI

struct Book: Identifiable {
    private(set) var id = UUID()
    let title: String
    let author: String
    let color: Color
    let coverName: String
    let description: String
    
    var byLine: String {
        "\(title) by \(author)"
    }
}

extension Book: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(author)
        hasher.combine(color)
        hasher.combine(coverName)
        hasher.combine(description)
    }
}
