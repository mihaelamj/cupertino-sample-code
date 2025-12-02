/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension on the main app class that creates the compositor layer.
*/

import SwiftUI
import RealityKit

import CompositorServices

import ModelIO
import ARKit
@preconcurrency import MetalKit

import os.log

extension CompositorServicesHoverEffectApp {
    
    func makeCompositorLayer(
        _ context: CompositorLayerContext
    ) -> CompositorLayer {
        CompositorLayer(configuration: { capabilities, configuration in
            
            // Set the buffer formats for the depth and color buffer.
            configuration.depthFormat = .depth32Float
            configuration.colorFormat = .bgra8Unorm_srgb

            // If the device supports foveation, enable or disable it based
            // on the user's stored preferences in the app model.
            if capabilities.supportsFoveation {
                configuration.isFoveationEnabled = appModel.foveation
            }
            
            // Set up features requiring visionOS 26 or later.
            if #available(visionOS 26.0, *), appModel.withHover {
                // Enable the tracking area buffer for Metal.
                configuration.trackingAreasFormat = .r8Uint
                
                // Specify how to use that data.
                if appModel.withHover && appModel.useMSAA {
                    configuration.trackingAreasUsage = [.shaderWrite, .shaderRead]
                } else {
                    configuration.trackingAreasUsage = [.renderTarget, .shaderRead]
                }
                
                // Override the render-quality resolution, if requested.
                if appModel.overrideResolution {
                    configuration.maxRenderQuality = .init(appModel.resolution)
                }
            }
            
        }) { renderer in
            render(renderer, context: context)
        }
    }
    
}
