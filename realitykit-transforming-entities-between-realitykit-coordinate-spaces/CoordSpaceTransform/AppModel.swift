/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model that the app uses in multiple views.
*/

import RealityKit
import SwiftUI

enum ImmersiveSpaceState {
    case closed
    case inTransition
    case open
}

/// The observable data model that contains information for the
/// volumetric view, the immersive view, and the app.
@Observable
class AppModel {
    /// The state of the immersive space, indicating whether the window is closed, backgrounded, or active.
    var immersiveSpaceState = ImmersiveSpaceState.closed

    /// A Boolean value that indicates whether the cube is in immersive space.
    var cubeInImmersiveSpace = false

    /// The cube entity in the volumetric window to move to the immersive space.
    var volumeCube = Entity()

    /// An entity that stores the last transform of the volume cube before it moves to an immersive space.
    var volumeCubeLastSceneTransformEntity = Entity()

    /// The root entity that the volume cube is a subentity of when in the volumetric window.
    var volumeRootEntity = Entity()

    /// The root entity that the volume cube is a subentity of when in the immersive space.
    var immersiveSpaceRootEntity = Entity()

    /// The transform of the cube relative to the scene coordinate space.
    var sceneTransform = Transform.identity

    /// The transform of the cube relative to the immersive space coordinate space.
    var spaceTransform = Transform.identity

    /// The material of the cube when it's in the volumetric window.
    let volumetricMaterial = SimpleMaterial(
        color: .blue, roughness: 0.25, isMetallic: false)

    /// The material of the cube when it's in the immersive space.
    let immersiveSpaceMaterial = SimpleMaterial(
        color: .red, roughness: 0.25, isMetallic: false)

    /// The attachment that displays the cube's translation relative to the scene coordinate space.
    var sceneAttachmentEntity: Entity?

    /// The drag gesture property associated with the volume cube.
    var dragUpdateTransforms: some Gesture {
        DragGesture()
            .targetedToEntity(volumeCube)
            .onChanged(updateTransformsWhileDragging)
    }

    typealias DragGestureInfo = EntityTargetValue<DragGesture.Value>

    /// Updates the transforms relative to the scene and immersive space.
    ///
    /// Sets the position of the volume cube after converting the 3D location from SwiftUI local coordinate space
    /// to the coordinate space of the volume cube's root.
    /// - Parameter dragGestureInfo: Information regarding the drag gesture that sets the volume cube's position.
    func updateTransformsWhileDragging(
        _ dragGestureInfo: DragGestureInfo
    ) {
        guard let volumeCubeRoot = volumeCube.parent else { return }
        
        // Convert the 3D point of the drag from the local SwiftUI coordinate space
        // to the coordinate space of the volume cube's root.
        volumeCube.position = dragGestureInfo.convert(
            dragGestureInfo.location3D, from: .local, to: volumeCubeRoot)
        
        // Update both scene and immersive space transforms of the volume cube.
        updateTransform(relativeTo: .scene)
        updateTransform(relativeTo: .immersiveSpace)
    }

    /// Updates the transforms of the cube relative to a specific reference space.
    /// - Parameter referenceSpace: The reference space to transform.
    func updateTransform(
        relativeTo referenceSpace: Entity.CoordinateSpaceReference
    ) {
        guard
            let cubeToReferenceSpaceMatrix = volumeCube.transformMatrix(
                relativeTo: referenceSpace)
        else { return }

        switch referenceSpace {
        case .scene:
            sceneTransform = Transform(matrix: cubeToReferenceSpaceMatrix)
        case .immersiveSpace:
            spaceTransform = Transform(matrix: cubeToReferenceSpaceMatrix)
        default:
            print("Unknown reference space: \(referenceSpace)")
        }
    }

    /// Moves the cube from the immersive space to the volumetric window.
    func moveCubeFromImmersiveSpaceToVolumetricWindow() {

        // Get the transformation matrix of the volume cube's previously
        // recorded transform relative to the immersive space.
        let cubeToSpaceMatrix =
            volumeCubeLastSceneTransformEntity.transformMatrix(
                relativeTo: .immersiveSpace)
        
        // Create a transform from the transformation matrix.
        let cubeToSpaceTransform = Transform(
            matrix: cubeToSpaceMatrix ?? matrix_identity_float4x4)
        
        // Move the volume cube to its previously recorded transform
        // over a period of time.
        volumeCube.move(
            to: cubeToSpaceTransform,
            relativeTo: nil,
            duration: getDurationBasedOnDistance(durationMaxLimit: 2.0),
            timingFunction: .easeOut)
    }

    /// Calculates the duration of the move animation in seconds as a factor of the distance between the
    /// volume cube's current position and previous position.
    ///
    /// The longer the distance, the longer it takes to get to the position. Use the `durationMaxLimit` parameter
    /// to specify a maximum number of seconds for the animation.
    /// - Parameter durationMaxLimit: The maximum duration that the move animation is limited to, in seconds.
    /// - Returns: The duration, calculated in seconds.
    func getDurationBasedOnDistance(durationMaxLimit: TimeInterval) -> TimeInterval {

        let cubeToSpaceMatrix = volumeCubeLastSceneTransformEntity
            .transformMatrix(relativeTo: .immersiveSpace)

        let cubeToSpaceTransform = Transform(
            matrix: cubeToSpaceMatrix ?? matrix_identity_float4x4)

        let distance = simd_distance_squared(
            simd_double3(volumeCube.transform.translation),
            simd_double3(cubeToSpaceTransform.translation))

        return min(distance, durationMaxLimit)
    }

    /// Makes the cube a subentity of the volumetric window and
    /// sets the transform value to the previously recorded transform.
    func makeCubeSubEntityOfVolumeRoot() {
        
        // Make the volume cube a subentity of the volumetric window's root.
        volumeRootEntity.addChild(volumeCube)
        
        // Set the transform to the last recorded transform.
        volumeCube.transform =
            volumeCubeLastSceneTransformEntity.transform
        
        // Set the material to the volumetric material.
        volumeCube.components[ModelComponent.self]?.materials = [
            volumetricMaterial
        ]
        
        // Update the scene and immersive space transforms.
        updateTransform(relativeTo: .scene)
        updateTransform(relativeTo: .immersiveSpace)
        
        // Enable the scene transform attachment because the cube is in the
        // volumetric window.
        sceneAttachmentEntity?.isEnabled = true
        
        cubeInImmersiveSpace = false
    }
}
