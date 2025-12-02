/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The component containing attack behavior of enemies.
*/

import Foundation
import RealityKit

/// The component containing attack behavior of enemies.
public struct AttackComponent: Component {
    public var lastAttackTime: TimeInterval = 0
    public var attackDelay: TimeInterval = 1.0
}
