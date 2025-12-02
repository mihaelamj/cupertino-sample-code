/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A Locked Camera Capture extension for AVCam.
*/

import Foundation
import LockedCameraCapture
import SwiftUI
import os

@main
struct AVCamCaptureExtension: LockedCameraCaptureExtension {
    
    @State private var camera = CameraModel()
    
    var body: some LockedCameraCaptureExtensionScene {
        LockedCameraCaptureUIScene { session in
            CameraView(camera: camera)
                .statusBarHidden(true)
                .task {
                    // Start the capture pipeline.
                    await camera.start()
                }
        }
    }
}

/// A global logger for the app.
let logger = Logger()
