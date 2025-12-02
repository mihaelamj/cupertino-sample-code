/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Adds an initializer function that takes a function instead of a protocol.
*/
import SwiftUI
import RealityKit

import CompositorServices

import ModelIO
import ARKit
import MetalKit

struct CompositorLayerContext {
    #if os(macOS)
    var remoteDeviceIdentifier: RemoteDeviceIdentifier?
    #endif
}

extension CompositorLayer {
    /// Creates an instance of `CompositorLayer`.
    /// - Parameters:
    ///   - configuration: The closure to call to configure the layer renderer.
    ///   - renderer: The function to call when rendering is required.
    init(
        configuration: @escaping (LayerRenderer.Capabilities, inout LayerRenderer.Configuration) -> Void,
        _ rendererClosure: @escaping (LayerRenderer) -> Void
    ) {
        struct Configuration: CompositorLayerConfiguration {
            let closure: (LayerRenderer.Capabilities, inout LayerRenderer.Configuration) -> Void

            func makeConfiguration(capabilities: LayerRenderer.Capabilities, configuration: inout LayerRenderer.Configuration) {
                closure(capabilities, &configuration)
            }
        }
        self.init(
            configuration: Configuration(closure: configuration),
            renderer: rendererClosure
        )
    }
}
