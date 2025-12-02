/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main user interface for the sample app.
*/

import SwiftUI
import AVFoundation
import AVKit
import Combine

@MainActor
struct CameraView<CameraModel: Camera>: View {
    
    @State var camera: CameraModel
    
    var body: some View {
        ZStack {
            // A container view that manages the placement of the preview.
            PreviewContainer(camera: camera) {
                ZStack {
                    // A view that provides a preview of the captured content.
                    CameraPreview(preview: camera.preview)
                    // Handle capture events from device hardware buttons.
                        .onCameraCaptureEvent { event in
                            if event.phase == .ended {
                                Task {
                                    await camera.toggleRecording()
                                }
                            }
                        }
                    FocusOverlayView(camera: camera)
                }
            }
            // The main camera user interface.
            CameraUI(camera: camera)
        }
    }
}

#if DEBUG
#Preview {
    CameraView(camera: PreviewCameraModel())
}
#endif
