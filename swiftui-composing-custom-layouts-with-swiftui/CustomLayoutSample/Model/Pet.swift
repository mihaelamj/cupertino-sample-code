/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A representation of a single pet.
*/

import SwiftUI

/// A type of pet that people can vote for.
struct Pet: Identifiable, Equatable {
    /// The name of the pet's type, like cat or dog.
    let type: String

    /// A color to use for the pet's avatar.
    let color: Color

    /// The total votes that the pet has received.
    var votes: Int = 0

    /// An identifier that's unique for each pet.
    ///
    /// This structure uses the pet's type as the identifier. This assumes
    /// that no two pet's have the same type string.
    var id: String { type }
}
