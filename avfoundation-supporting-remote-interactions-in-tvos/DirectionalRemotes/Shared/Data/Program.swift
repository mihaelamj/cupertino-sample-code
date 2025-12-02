/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents a TV program.
*/

import Foundation

/// A representation of a TV program.
struct Program {
    /// The program title.
    let title: String
    /// The program description.
    let description: String
    /// The string that represents the URL of the HLS playlist for the program.
    let playlistURLString: String
    /// A `Boolean` value that indicates whether the program is live, which is `false` by default.
    let isLive: Bool = false

    /// The URL of the HLS playlist for the program.
    var playlistURL: URL {
        URL(string: playlistURLString)!
    }
}
