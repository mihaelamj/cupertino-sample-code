/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The postprocessing effect pipeline for blooming.
*/

import Foundation
import RealityKit
import Metal
import MetalPerformanceShaders
import SwiftUI
import Combine

@available(visionOS, unavailable)
@available(macOS, introduced: 26.0)
@available(iOS, introduced: 26.0)
@available(tvOS, introduced: 26.0)
final class BloomEffect: PostProcessEffect, @unchecked Sendable {

    var bloomTexture: MTLTexture?
    var illuminationTexture: MTLTexture?

    let bloomThreshold: Float = 0.55
    let bloomBlur: Float = 40.0

    init() {}

    func postProcess(context: borrowing PostProcessEffectContext<any MTLCommandBuffer>) {
        let commandBuffer = context.commandBuffer
        if bloomTexture == nil ||
            bloomTexture?.width != context.sourceColorTexture.width ||
            bloomTexture?.height != context.sourceColorTexture.height {
            bloomTexture = makeEmptyTextureLike(context.sourceColorTexture, device: context.device)
            illuminationTexture = makeEmptyTextureLike(context.sourceColorTexture, device: context.device)
        }
        guard let illuminationTexture, var bloomTexture else { return }

        let brightness = MPSImageThresholdToZero(
            device: context.device,
            thresholdValue: bloomThreshold,
            linearGrayColorTransform: [1.1, 0.2, -0.3]
        )

        brightness.encode(
            commandBuffer: commandBuffer,
            sourceTexture: context.sourceColorTexture,
            destinationTexture: illuminationTexture
        )

        let multiply = MPSImageMultiply(device: context.device)
        multiply.primaryScale = 1.0
        multiply.secondaryScale = 1.0
        multiply.bias = 0.0
        multiply.encode(
            commandBuffer: commandBuffer,
            primaryTexture: illuminationTexture,
            secondaryTexture: context.sourceColorTexture,
            destinationTexture: bloomTexture
        )
        let gaussianBlur = MPSImageGaussianBlur(device: context.device, sigma: bloomBlur)
        gaussianBlur.encode(commandBuffer: commandBuffer, inPlaceTexture: &bloomTexture)

        let add = MPSImageAdd(device: context.device)
        add.primaryScale = 0.7
        add.secondaryScale = 0.6
        add.encode(commandBuffer: commandBuffer,
                   primaryTexture: context.sourceColorTexture,
                   secondaryTexture: bloomTexture,
                   destinationTexture: context.targetColorTexture)
    }

    func makeEmptyTextureLike(_ source: MTLTexture, device: MTLDevice) -> MTLTexture? {
        let desc = MTLTextureDescriptor()
        desc.textureType = source.textureType
        desc.pixelFormat = source.pixelFormat
        desc.width = source.width
        desc.height = source.height
        desc.mipmapLevelCount = 1
        desc.usage = [.shaderRead, .shaderWrite]
        desc.storageMode = .shared
        guard let texture = device.makeTexture(descriptor: desc)
        else { return nil }

        let width = desc.width
        let height = desc.height
        let bytesPerPixel = {
            switch source.pixelFormat {
            case .bgra8Unorm_srgb: 4
            case .bgra10_xr_srgb: 5
            case .rgba16Float: 8
            default:
                fatalError("Unhandled pixel format \(source.pixelFormat)")
            }
        }()
        let bytesPerRow = width * bytesPerPixel
        let emptyData = [UInt8](repeating: 0, count: bytesPerRow * height)

        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: emptyData, bytesPerRow: bytesPerRow)
        return texture
    }
    static func deviceSupportsEffect() -> Bool {
        let device = MTLCreateSystemDefaultDevice()
        return device?.supportsFamily(.apple8) ?? false
    }
}
