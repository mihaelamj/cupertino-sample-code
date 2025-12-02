/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays an appropriate capture button for the selected mode.
*/

import SwiftUI

/// A view that displays an appropriate capture button for the selected mode.
@MainActor
struct CaptureButton<CameraModel: Camera>: View {
    
    @State var camera: CameraModel
    
    private let mainButtonDimension: CGFloat = 68
    
    var body: some View {
        captureButton
            .aspectRatio(1.0, contentMode: .fit)
            .frame(width: mainButtonDimension)
    }
    
    @ViewBuilder
    var captureButton: some View {
        MovieCaptureButton(camera: camera) {
            Task {
                await camera.toggleRecording()
            }
        }
    }
}

#Preview("Video") {
    CaptureButton(camera: PreviewCameraModel())
}

private struct MovieCaptureButton<CameraModel: Camera>: View {
    
    @State var camera: CameraModel
    
    private let action: () -> Void
    private let lineWidth = CGFloat(4.0)
    
    init(camera: CameraModel, action: @escaping () -> Void) {
        self.action = action
        self.camera = camera
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .foregroundColor(Color.white)
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    camera.isRecording.toggle()
                }
                action()
            } label: {
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: geometry.size.width / (camera.isRecording ? 4.0 : 2.0))
                        .inset(by: lineWidth * 1.2)
                        .fill(.red)
                        .scaleEffect(camera.isRecording ? 0.6 : 1.0)
                }
            }
            .buttonStyle(NoFadeButtonStyle())
        }
    }
    
    struct NoFadeButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
        }
    }
}
