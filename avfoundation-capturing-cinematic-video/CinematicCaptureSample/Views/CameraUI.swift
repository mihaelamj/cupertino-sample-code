/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents the main camera user interface.
*/

import SwiftUI
import AVFoundation

/// A view that presents the main camera user interface.
struct CameraUI<CameraModel: Camera>: View {

    @State var camera: CameraModel
    
    var body: some View {
        Group {
            compactUI
        }
        .overlay(alignment: .top) {
            RecordingTimeView(time: camera.captureActivity.currentTime)
        }
        .overlay {
            StatusOverlayView(status: camera.status)
        }
    }
    
    /// This view arranges UI elements vertically.
    @ViewBuilder
    var compactUI: some View {
        VStack(spacing: 0) {
            Spacer()
            SimulatedApertureView(camera: camera)
            MainToolbar(camera: camera)
                .padding(.bottom, bottomPadding)
        }
    }
    
    var bottomPadding: CGFloat {
        // Dynamically calculate the offset for the bottom toolbar in iOS.
        let bounds = UIScreen.main.bounds
        let rect = AVMakeRect(aspectRatio: movieAspectRatio, insideRect: bounds)
        return (rect.minY.rounded() / 2) + 12
    }
}

#if DEBUG
#Preview {
    CameraUI(camera: PreviewCameraModel())
}
#endif
