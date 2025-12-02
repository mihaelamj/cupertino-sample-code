/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model for a source.
*/

import EventKit

struct SourceModel: Identifiable, Hashable, Sendable {
    let id: String
    let sourceIdentifier: String
    let title: String
    
    init(sourceIdentifier: String, title: String) {
        self.id = UUID().uuidString
        self.sourceIdentifier = sourceIdentifier
        self.title = title
    }
}

extension SourceModel: Equatable {
    static func == (lhs: SourceModel, rhs: SourceModel) -> Bool {
        return lhs.id == rhs.id &&
        lhs.sourceIdentifier == rhs.sourceIdentifier &&
        lhs.title == rhs.title
    }
}

extension SourceModel {
    init(source: EKSource) {
        self.init(sourceIdentifier: source.sourceIdentifier, title: source.title)
    }
}
