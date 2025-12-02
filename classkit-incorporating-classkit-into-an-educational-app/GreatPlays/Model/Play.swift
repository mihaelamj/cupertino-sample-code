/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model object that represents a play.
*/

import Foundation

/// An individual play.
struct Play {
    // The title of the play.
    var title: String

    // A list of acts.
    var acts: [Act] = []
    
    /// Initializes the play with a title.
    init(title: String) {
        self.title = title
    }
}
