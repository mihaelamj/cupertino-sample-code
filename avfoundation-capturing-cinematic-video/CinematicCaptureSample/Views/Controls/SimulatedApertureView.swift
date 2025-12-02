/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that adjusts the camera's simulated aperture.
*/

import SwiftUI

/// A view that toggles the camera's capture mode.
struct SimulatedApertureView<CameraModel: Camera>: View {
    
    @State var camera: CameraModel

    let minSimulatedAperture: Float
    let maxSimulatedAperture: Float

    @State private var apertureTimer: Timer?
    @State private var isSliderEditing = false
    
    init(camera: CameraModel) {
        self.camera = camera
        minSimulatedAperture = camera.minSimulatedAperture
        maxSimulatedAperture = camera.maxSimulatedAperture
    }
    
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Image(systemName: "f.cursive.circle.fill")
                Text("\(camera.simulatedAperture, specifier: "%.1f")")
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isSliderEditing ? .thinMaterial : .ultraThinMaterial)
            .opacity(isSliderEditing ? 1 : 0.6)
            .clipShape(.capsule)

            Slider(value: $camera.simulatedAperture, in: minSimulatedAperture...maxSimulatedAperture) {
            } minimumValueLabel: {
                Text("\(minSimulatedAperture, specifier: "%.1f")")
            } maximumValueLabel: {
                Text("\(maxSimulatedAperture, specifier: "%.1f")")
            }
            .disabled(camera.captureActivity.isRecording)
        }
        .padding()
    }
}

#if DEBUG
#Preview {
    SimulatedApertureView(camera: PreviewCameraModel())
}
#endif
