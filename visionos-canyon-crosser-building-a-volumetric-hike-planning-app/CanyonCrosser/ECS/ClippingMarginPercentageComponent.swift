/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component to hold the details about the clipping margins.
*/

import SwiftUI
import RealityKit

struct ClippingMarginPercentageComponent: Component {
    @Observable
    class Environment: CustomDebugStringConvertible {
        var contentViewBounds: BoundingBox = .empty
        var sceneViewBounds: BoundingBox = .empty
        var volumeInMeters: BoundingBox = .empty
        var clippingMargins: BoundingBox = .empty
        var debugDescription: String {
            """
            contentViewBounds: \(contentViewBounds)
            sceneViewBounds: \(sceneViewBounds)
            clippingMargins: \(clippingMargins)
            volumeInMeters: \(volumeInMeters)
            """
        }
    }

    @Observable
    class Values: CustomDebugStringConvertible {
        var clippingMarginPercentage: SIMD3<Float> = .zero
        var inVolume: Bool = false
        var inVisibleArea: Bool = false

        var debugDescription: String {
            """
            clippingMarginPercentage: \(clippingMarginPercentage)
            inVolume: \(inVolume)
            inVisibleArea: \(inVisibleArea)
            """
        }
    }

    var environment: Environment
    var values: Values

    var lastContentViewBounds: BoundingBox = .empty
    var lastSceneViewBounds: BoundingBox = .empty
    var lastClippingMargins: BoundingBox = .empty
    var lastPosition: SIMD3<Float> = .zero

    init(environment: Environment, values: Values? = nil) {
        self.environment = environment
        self.values = values ?? Values()
    }
}
