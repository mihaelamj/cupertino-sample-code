/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays a button to capture video.
*/

import SwiftUI

/// A view that displays an appropriate capture button for the selected mode.
@MainActor
struct CaptureButton<CameraModel: Camera>: View {
    
    @State var camera: CameraModel
    @State var isRecording = false
    
    var body: some View {
        MovieCaptureButton(isRecording: $isRecording) { _ in
            Task {
                await camera.toggleRecording()
            }
        }
        .frame(width: primaryButtonSize.width, height: primaryButtonSize.height)
        // Respond to recording state changes that occur from hardware button presses.
        .onChange(of: camera.captureActivity.isRecording) { _, newValue in
            // Ensure the button animation occurs when toggling recording state from a hardware button.
            withAnimation(.easeInOut(duration: 0.25)) {
                isRecording = newValue
            }
        }
    }
}

private struct MovieCaptureButton: View {

    private let action: (Bool) -> Void
    private let lineWidth: CGFloat = 4.0

    @State private var buttonWidth: CGFloat = 0
    @Binding private var isRecording: Bool

    init(isRecording: Binding<Bool>, action: @escaping (Bool) -> Void) {
        _isRecording = isRecording
        self.action = action
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .foregroundColor(Color.white)
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isRecording.toggle()
                }
                action(isRecording)
            } label: {
                RoundedRectangle(cornerRadius: buttonWidth / (isRecording ? 4.0 : 2.0))
                    .inset(by: lineWidth * 1.2)
                    .fill(.red)
                    .scaleEffect(isRecording ? 0.6 : 1.0)
            }
            .buttonStyle(NoFadeButtonStyle())
        }
        .accessibilityLabel("\(isRecording ? "Stop" : "Start") recording")
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newValue in
            buttonWidth = newValue
        }
    }

    struct NoFadeButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
        }
    }
}

#if DEBUG
#Preview("PreviewLayer") {
    CaptureButton(camera: PreviewCameraModel(captureMode: .previewLayer))
}

#Preview("VideoDataOutput") {
    CaptureButton(camera: PreviewCameraModel(captureMode: .videoDataOutput))
}
#endif
