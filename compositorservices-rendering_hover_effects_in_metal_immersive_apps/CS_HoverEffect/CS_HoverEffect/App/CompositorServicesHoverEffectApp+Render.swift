/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension on the app containing the main render loop.
*/

import SwiftUI
import RealityKit

import CompositorServices

import ModelIO
import ARKit
@preconcurrency import MetalKit

import os.log

extension CompositorServicesHoverEffectApp {
    func render(_ renderer: LayerRenderer, context: CompositorLayerContext) {

        Task(priority: .high) {
            let renderData = RenderData(
                layerRenderer: renderer,
                context: context,
                theAppModel: appModel
            )
            await renderData.setUpWorldTracking()
            await renderData.loadAssets()
            await renderData.setUpTileResolvePipeline()
            await renderData.setUpShaderPipeline()
            
            if #available(visionOS 26.0, *) {
                renderer.onSpatialEvent = { events in
                    for event in events {
                        logger.log(level: .info, "Received spatial event:\(String(describing: event), privacy: .public)")
                        let id = event.trackingAreaIdentifier.rawValue
                        let phase = event.phase
                        if id != 0 && phase == .ended {
                            Task(priority: .userInitiated) {
                                await renderData.tap(on: id)
                            }
                        }
                    }
                }
            }
            await renderData.renderLoop()
        }
    }
}
