/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents a channel.
*/

import Foundation

/// A representation of a TV channel.
struct Channel {
    /// The name of the channel.
    let name: String
    /// The channel's list of programs.
    var programs: [Program]

    /// The channel's current program.
    var currentProgram: Program? {
        programs.first
    }
}
