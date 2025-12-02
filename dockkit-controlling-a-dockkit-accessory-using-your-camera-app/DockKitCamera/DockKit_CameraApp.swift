/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A sample app that shows how to a use the DockKit APIs to interface with a DockKit accessory.
*/

import os
import SwiftUI

@main
struct DockKitCameraApp: App {
    
    @State private var camera = CameraModel()
    
    @State private var dockController = DockControllerModel()

    var body: some Scene {
        WindowGroup {
            ContentView(camera: camera, dockController: dockController)
                .task {
                    await camera.setTrackingServiceDelegate(dockController)
                    await dockController.setCameraCaptureServiceDelegate(camera)
                    // Start the capture pipeline.
                    await camera.start()
                }
        }
    }
}

/// A global logger for the app.
let logger = Logger()
