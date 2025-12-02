/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model object that represents a scene of an act.
*/

import Foundation

/// One scene in an Act.
class Scene {
    /// The act in which the scene occurs.
    var act: Act

    /// The number of the scene.
    var number: Int
    
    /// A quiz about the scene.
    var quiz: Quiz?
    
    /// Initializes a scene with a scene number and the corresponding act.
    init(number: Int, act: Act) {
        self.number = number
        self.act = act
    }
}
