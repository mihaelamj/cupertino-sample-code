/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that stores the entity to set the light relative to.
*/

import RealityKit

struct LightRotationComponent: Component {
    /// The entity to set the orientation relative to in the system.
    var landmarkEntity: Entity
}
