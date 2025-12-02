/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension on `GrandCanyonView` to set up margins and position assets.
*/

import SwiftUI
import RealityKit
import RealityKitContent

extension GrandCanyonView {
    
    /// Performs the necessary calculations to update the clipping margin environment with the current view bounds and window clipping margins.
    func updateMarginClippingEnvironment(in content: RealityViewContent) {
        appModel.clippingMarginEnvironment.contentViewBounds = content.convert(
            volumeSize,
            from: .local,
            to: content
        )

        appModel.clippingMarginEnvironment.sceneViewBounds = content.convert(
            volumeSize,
            from: .local,
            to: .scene
        )

        appModel.clippingMarginEnvironment.clippingMargins = physicalMetrics.convert(edges: windowClippingMargins, to: .meters)
    }
 
    /// Performs the necessary calculations to position and scale the Grand Canyon model to fill the view bounds and sit at the bottom of the volume.
    func positionAndScale(with content: RealityViewContent) {
        guard volumeSize != .zero else {
            return
        }

        // Convert the view bounds volume size from the local coordinate space to the RealityKit coordinate space.
        let viewBounds = content.convert(
            volumeSize,
            from: .local,
            to: content
        )

        /// The scale required for the terrain to fill the bounds of the volumetric window.
        let scale = (viewBounds.extents / appModel.terrainEntityBaseExtents).min()

        // Set the scale relative to the scene.
        appModel.grandCanyonEntity.setScale(SIMD3<Float>(repeating: scale), relativeTo: nil)
        
        // Get the current position and visual bounds of the Grand Canyon model.
        let grandCanyonPosition = appModel.grandCanyonEntity.position(relativeTo: nil)
        let visualBoundsInScene = appModel.grandCanyonEntity.visualBounds(relativeTo: nil, excludeInactive: true)
        // Normalize the location to get the position as a percentage of the visual bounds.
        let normalizedLocation = (grandCanyonPosition - visualBoundsInScene.min) / visualBoundsInScene.extents
        // Set the position so the minimum y of the visual bounds is the same as the view bounds.
        let viewBaseYPosition = viewBounds.min.y + normalizedLocation.y * visualBoundsInScene.extents.y
        appModel.grandCanyonEntity.setPosition(SIMD3<Float>(grandCanyonPosition.x, viewBaseYPosition, grandCanyonPosition.z), relativeTo: nil)
        
        // Update the scale of the light collection entity so that it's always at the initial scale relative to the root.
        // Changing the scale changes the distance of the spotlight to the geometry, so inversely scale the light group to counteract it.
        // This keeps the overall visual intensity of the light the same.
        guard let lightCollectionEntity = appModel.grandCanyonEntity.findEntity(named: "EarthRotate") else {
            return
        }
     
        // Use the entity scale from Reality Composer Pro.
        let grandCanyonEntityScaleInRCP: Float = 1.383
        lightCollectionEntity.setScale(SIMD3<Float>(repeating: grandCanyonEntityScaleInRCP), relativeTo: nil)
    }
}
