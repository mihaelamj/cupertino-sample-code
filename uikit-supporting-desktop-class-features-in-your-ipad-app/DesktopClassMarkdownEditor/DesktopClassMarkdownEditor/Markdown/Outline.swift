/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that represents a navigatable element of a Markdown document.
*/

import Foundation

struct OutlineElement: Hashable, CustomDebugStringConvertible {
    let representation: OutlineRepresentation
    /// The range of the element, including Markdown tags.
    let range: NSRange
    let text: String
    let indendationLevel: Int
    let nodeIdentifier: UUID
    
    var debugDescription: String {
        "\(indendationLevel) - [\(representation):\(range.lowerBound)-\(range.upperBound)] \(text.prefix(20))"
    }
}

enum OutlineRepresentation: Hashable, CustomDebugStringConvertible {
    case heading(_ level: Int)
    case codeBlock(MarkdownTag.Language)

    var debugDescription: String {
        switch self {
        case .heading(let level):
            return "H\(level)"
        case .codeBlock(let language):
            return "\(language.rawValue) Code"
        }
    }
}
