/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents the main camera user interface.
*/

import SwiftUI
import AVFoundation

/// A view that presents the main camera user interface.
struct CameraUI<CameraModel: Camera, DockControllerModel: DockController>: View {

    @State var camera: CameraModel
    @State var dockController: DockControllerModel
    
    var body: some View {
        VStack(spacing: 0) {
            StatusView(dockController: dockController)
            Spacer()
            ZoomView(zoomValue: camera.zoomFactor)
            MainToolbar(camera: camera, dockController: dockController)
                .padding(.bottom, bottomPadding)
        }
        .overlay(alignment: .top) {
            RecordingTimeView(time: camera.captureActivity.currentTime)
                .offset(y: 0)
        }
        
    }
    
    var bottomPadding: CGFloat {
        // Dynamically calculate the offset for the bottom toolbar in iOS.
        let bounds = UIScreen.main.bounds
        let rect = AVMakeRect(aspectRatio: movieAspectRatio, insideRect: bounds)
        return (rect.minY.rounded() / 2) + 12
    }
}

#Preview {
    CameraUI(camera: PreviewCameraModel(), dockController: PreviewDockControllerModel())
}
