/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays a button to switch between available cameras.
*/

import SwiftUI

/// A view that displays a button to switch between available cameras.
struct SwitchCameraButton<CameraModel: Camera>: View {
    
    @State var camera: CameraModel
    
    var body: some View {
        Button {
            Task {
                await camera.switchVideoDevices()
            }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
        }
        .accessibilityLabel("Switch cameras")
        .buttonStyle(SwitchCameraButtonStyle())
        .frame(width: secondaryButtonSize.width, height: secondaryButtonSize.height)
        .disabled(camera.captureActivity.isRecording)
        .allowsHitTesting(!camera.isSwitchingVideoDevices)
    }
}

private struct SwitchCameraButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isEnabled ? .primary : Color(white: 0.4))
            .font(.system(size: 24.0))
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .padding()
            .background(.black.opacity(0.4))
            .clipShape(.circle)
    }
}
