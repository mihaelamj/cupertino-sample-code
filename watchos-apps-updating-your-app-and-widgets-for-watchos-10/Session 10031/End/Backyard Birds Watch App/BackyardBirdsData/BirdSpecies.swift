/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Bird Species class.
*/

import Foundation

final class BirdSpecies {

    let id: String
    var name: String
    var summary: String

    init(id: String, name: String, summary: String) {
        self.id = id
        self.name = name
        self.summary = summary
    }
}

extension BirdSpecies {
    static let preview = BirdSpecies(
        id: "Fluffy Warbler",
        name: "Fluffy Warbler",
        summary: "This little cutie can be found anywhere on Earth, as well as occasionally on the moon."
    )

    static func all() -> [BirdSpecies] {
        [
            BirdSpecies(
                id: "Fluffy Warbler",
                name: "Fluffy Warbler",
                summary: "This little cutie can be found anywhere on Earth, as well as occasionally on the moon."
            ),

            BirdSpecies(
                id: "Jombo Wombus",
                name: "Jombo Wombus",
                summary: "Placeholder description for species 2"
            ),

            BirdSpecies(
                id: "Chibi Chirper",
                name: "Chibi Chirper",
                summary: "Placeholder description for species 3"
            ),

            BirdSpecies(
                id: "Crested Flapper",
                name: "Crested Flapper",
                summary: "Placeholder description for species 4"
            ),

            BirdSpecies(
                id: "Tufted Hopper",
                name: "Tufted Hopper",
                summary: "Placeholder description for species 5"
            ),

            BirdSpecies(
                id: "Buzzing Birdie",
                name: "Buzzing Birdie",
                summary: "Placeholder description for species 6"
            )
        ]
    }
}
