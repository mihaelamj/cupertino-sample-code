/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents the camera controls and preview.
*/

import SwiftUI
import AVKit

struct CameraView: View {
    @State var camera: Camera
    @Binding var imageData: Data?
    
    var body: some View {
        // A preview of the what the camera sees.
        CameraPreview(source: camera.previewSource)
            .overlay(alignment: .bottom) {
                // The take photo button.
                Circle()
                    .stroke(lineWidth: 4.0)
                    .fill(.white)
                    .frame(width: 68, height: 68)
                    .padding()
                Button(action: self.takePhoto) {
                    Circle()
                        .inset(by: 5)
                        .fill(.white)
                        .frame(width: 68, height: 68)
                        .padding()
                }.buttonStyle(PhotoButtonStyle())
            }
    }
    
    private func takePhoto() {
        Task {
            do {
                imageData = try await camera.capturePhoto()
            } catch {
                print(error)
            }
        }
    }
    
    struct PhotoButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}
