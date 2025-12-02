/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Data structures the app uses.
*/

import Foundation
import Metal
@preconcurrency import MetalKit

/// A material to use for rendering a mesh.
struct DrawCallMaterial {
    var texture: MTLTexture?
    var color: SIMD4<Float>?
}

/// A single draw call that makes up a scene.
struct DrawCall: Sendable {
    var transformWhole: simd_float4x4
    var transformExploded: simd_float4x4
    var mesh: MTKMesh
    var boundingBox: MDLAxisAlignedBoundingBox
    var materials: [DrawCallMaterial]

    var animationState: AnimationState = .idle
}

/// A collection of draw calls that make up a scene.
actor Scene {
    var animationTime: TimeInterval = 0
    var hasExpanded: Bool = false

    var drawCalls: [DrawCall] = []

    func add(_ drawcall: DrawCall) {
        drawCalls.append(drawcall)
    }
}

/// A cache of constant buffers to use for each drawable.
struct ShaderConstants: Hashable {
    var color: Bool
    var texture: Bool
    var normals: Bool = true
    var debugColors: Bool
}

/// A cache of textures to use for each drawable.
struct TextureCache {
    var perDrawable: [Int: MTLTexture] = [:]
}
