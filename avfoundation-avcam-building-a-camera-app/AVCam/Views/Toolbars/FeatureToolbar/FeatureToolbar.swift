/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents controls to enable capture features.
*/

import SwiftUI

/// A view that presents controls to enable capture features.
struct FeaturesToolbar<CameraModel: Camera>: PlatformView {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State var camera: CameraModel
    
    var body: some View {
        HStack(spacing: 30) {
            Spacer()
            switch camera.captureMode {
            case .photo:
                livePhotoButton
                prioritizePicker
            case .video:
                if camera.isHDRVideoSupported {
                    hdrButton
                }
            }
        }
        .buttonStyle(DefaultButtonStyle(size: isRegularSize ? .large : .small))
        .padding([.leading, .trailing])
        // Hide the toolbar items when a person interacts with capture controls.
        .opacity(camera.prefersMinimizedUI ? 0 : 1)
    }
    
    //  A button to toggle the enabled state of Live Photo capture.
    var livePhotoButton: some View {
        Button {
            camera.isLivePhotoEnabled.toggle()
        } label: {
            Image(systemName: camera.isLivePhotoEnabled ? "livephoto" : "livephoto.slash")
        }
    }
    
    @ViewBuilder
    var prioritizePicker: some View {
        Menu {
            Picker("Quality Prioritization", selection: $camera.qualityPrioritization) {
                ForEach(QualityPrioritization.allCases) {
                    Text($0.description)
                        .font(.body.weight(.bold))
                }
            }

        } label: {
            switch camera.qualityPrioritization {
            case .speed:
                Image(systemName: "dial.low")
            case .balanced:
                Image(systemName: "dial.medium")
            case .quality:
                Image(systemName: "dial.high")
            }
        }
    }

    @ViewBuilder
    var hdrButton: some View {
        if isCompactSize {
            hdrToggleButton
        } else {
            hdrToggleButton
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
        }
    }
    
    var hdrToggleButton: some View {
        Button {
            camera.isHDRVideoEnabled.toggle()
        } label: {
            Text("HDR \(camera.isHDRVideoEnabled ? "On" : "Off")")
                .font(.body.weight(.semibold))
        }
        .disabled(camera.captureActivity.isRecording)
    }
    
    @ViewBuilder
    var compactSpacer: some View {
        if !isRegularSize {
            Spacer()
        }
    }
}
