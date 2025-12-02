/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system to set the clipping margins on the volume.
*/

import SwiftUI
import RealityKit

/// The ClippingMarginPercentageSystem sets a `clippingMarginPercentage` value on the `ClippingMarginPercentageComponent`.
struct ClippingMarginPercentageSystem: RealityKit.System {
    static let query = EntityQuery(where: .has(ClippingMarginPercentageComponent.self))

    init(scene: RealityKit.Scene) { }

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var component = entity.components[ClippingMarginPercentageComponent.self] else {
                continue
            }

            let entityScenePosition = entity.position(relativeTo: nil)

            guard
                component.environment.contentViewBounds != component.lastContentViewBounds
                    || component.environment.clippingMargins != component.lastClippingMargins
                    || entityScenePosition != component.lastPosition
            else {
                continue
            }

            component.lastContentViewBounds = component.environment.contentViewBounds
            component.lastClippingMargins = component.environment.clippingMargins
            component.lastPosition = entityScenePosition

            let viewBounds = component.environment.sceneViewBounds
            let clippingMargins = component.environment.clippingMargins

            component.values.inVolume = viewBounds.contains(entityScenePosition)
            component.values.inVisibleArea = viewBounds.adding(margins: clippingMargins).contains(entityScenePosition)
            component.values.clippingMarginPercentage = clippingMarginPercentage(
                position: entityScenePosition,
                viewBounds: viewBounds,
                clippingMargins: clippingMargins
            )
            entity.components[ClippingMarginPercentageComponent.self] = component
        }
    }
}

extension ClippingMarginPercentageSystem {
    private func clippingMarginPercentage(position: SIMD3<Float>, viewBounds: BoundingBox, clippingMargins: BoundingBox) -> SIMD3<Float> {
        let distanceOutsideLeading  = max(0, viewBounds.min.x - position.x)
        let distanceOutsideTrailing = max(0, position.x - viewBounds.max.x)
        let distanceOutsideBack     = max(0, viewBounds.min.z - position.z)
        let distanceOutsideTop      = max(0, position.y - viewBounds.max.y)
        let distanceOutsideBottom   = max(0, viewBounds.min.y - position.y)

        let percentageOutsideLeading  = distanceOutsideLeading / clippingMargins.min.x
        let percentageOutsideTrailing = distanceOutsideTrailing / clippingMargins.max.x
        let percentageOutsideBack     = distanceOutsideBack / clippingMargins.min.z
        let percentageOutsideTop      = distanceOutsideTop / clippingMargins.max.y
        let percentageOutsideBottom   = distanceOutsideBottom / clippingMargins.min.y

        return SIMD3<Float>(
            x: value(positive: percentageOutsideLeading, negative: percentageOutsideTrailing),
            y: value(positive: percentageOutsideTop, negative: percentageOutsideBottom),
            z: value(positive: 0, negative: percentageOutsideBack),
        )
    }

    private func value(positive: Float, negative: Float) -> Float {
        if positive > 0 {
            return positive
        }

        if negative > 0 {
            return -negative
        }

        return 0
    }
}
