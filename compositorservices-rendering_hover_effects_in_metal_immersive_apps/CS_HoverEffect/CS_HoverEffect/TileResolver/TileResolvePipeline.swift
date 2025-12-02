/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Metal data types that the app's shaders use.
*/
import SwiftUI
import RealityKit

import CompositorServices

import ModelIO
import ARKit
import MetalKit

/// A pipeline for resolving the correct draw call ID for pixels that Metal MSAA affects.
struct TileResolvePipeline {

    let indexResolveState: MTLRenderPipelineState

    init(device: MTLDevice, configuration: LayerRenderer.Configuration) {

        let desc = MTLTileRenderPipelineDescriptor()
        desc.colorAttachments[0].pixelFormat = configuration.colorFormat
        if #available(visionOS 26.0, *) {
            desc.colorAttachments[1].pixelFormat = configuration.trackingAreasFormat
        }
        desc.rasterSampleCount = 4
        desc.threadgroupSizeMatchesTileSize = true

        let constants = MTLFunctionConstantValues()
        var useTextureArray = configuration.layout == .layered
        constants.setConstantValue(&useTextureArray, type: .bool, index: Int(FunctionConstantUseTextureArray.rawValue))

        let resolveFunction = try! device.makeDefaultLibrary()!
            .makeFunction(name: "block_resolve", constantValues: constants)

        desc.tileFunction = resolveFunction
        indexResolveState = try! device.makeRenderPipelineState(tileDescriptor: desc, options: .init()).0
    }
}
