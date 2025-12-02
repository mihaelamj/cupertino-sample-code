/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app data model.
*/
import SwiftUI
import RealityKit

import CompositorServices

import ModelIO
import ARKit
@preconcurrency import MetalKit

import os.log

let logger = Logger(subsystem: "com.example.apple-samplecode.compositor-services-hover-effect", category: "General")

@Observable
class AppModel {
    
    /// The name of the space to use for immersive viewing.
    static let immersiveSpaceId = "Compositor Services"
    
    /// The flag indicating whether the immersive space is open.
    var isImmersiveSpaceOpen: Bool = false
    
    /// The flag indicating whether to show the hover effect.
    var withHover: Bool = true
    
    /// The flag indicating whether to show the background.
    var withBackground: Bool = true
    
    /// The flag indicating whether to override the resolution.
    var overrideResolution: Bool = false
    
    /// The resolution of the view.
    var resolution: Float = 1.0
    
    /// The flag indicating whether to use foveation.
    var foveation: Bool = true
    
    var debugFactor: Float = 0.0
    
    /// The URL of the model to load.
    var modelURL: URL {
        Bundle.main.url(
            forResource: "Scene/Monolith_Fragments/Monolith_Fragments",
            withExtension: "usdc",
        )!
    }

    static let supportsMSAA: Bool = MTLCreateSystemDefaultDevice()?.supports32BitMSAA ?? false

    /// The flag indicating whether to use MSAA.
    var useMSAA: Bool = supportsMSAA
}
