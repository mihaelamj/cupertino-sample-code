/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A set of data structures that represent a song, and a list of songs this sample uses as data.
*/

import SwiftUI

struct Song: Identifiable {
    enum Source: Equatable {
        case person1
        case person2(calledDibs: Bool)
        case person3
    }

    var id = UUID()
    var title: String
    var source: Source

    var person2CalledDibs: Bool {
        source == .person2(calledDibs: true)
    }

    init(_ title: String, source: Source) {
        self.title = title
        self.source = source
    }
}

enum Songs {
    static let all: [Song] = [
        .init("Song 1", source: .person1),
        .init("Song 2", source: .person1),
        .init("Song 3", source: .person1),

        .init("Song 4", source: .person2(calledDibs: false)),
        .init("Song 5", source: .person2(calledDibs: true)),
        .init("Song 6", source: .person2(calledDibs: true)),
        .init("Song 7", source: .person2(calledDibs: false)),
        .init("Song 8", source: .person2(calledDibs: true)),
        .init("Song 9", source: .person2(calledDibs: true)),
        .init("Song 10", source: .person2(calledDibs: true)),
        .init("Song 11", source: .person2(calledDibs: false)),
        .init("Song 12", source: .person2(calledDibs: false)),

        .init("Song 13", source: .person3),
        .init("Song 14", source: .person3),
        .init("Song 15", source: .person3),
        .init("Song 16", source: .person3),
        .init("Song 17", source: .person3),
        .init("Song 18", source: .person3)
    ]

    static let fromPerson1: [Song] = Songs.all.filter {
        $0.source == .person1
    }

    static let fromPerson2: [Song] = Songs.all.filter {
        switch $0.source {
        case .person2: true
        default: false
        }
    }

    static let fromPerson3: [Song] = Songs.all.filter {
        $0.source == .person3
    }
}
