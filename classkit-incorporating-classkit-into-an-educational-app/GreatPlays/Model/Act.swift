/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model object that represents an act in a play.
*/

import Foundation

/// An act in a play.
struct Act {
    // The play in which the act occurs.
    var play: Play
    
    // The act number.
    var number: Int
    
    /// A list of scenes in this act.
    var scenes: [Scene] = []
    
    /// Initializes the act with an act number and the corresponding play.
    init(number: Int, play: Play) {
        self.number = number
        self.play = play
    }
}
