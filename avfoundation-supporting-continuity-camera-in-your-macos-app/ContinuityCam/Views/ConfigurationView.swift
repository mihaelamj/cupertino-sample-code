/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that lays out the camera configuration controls.
*/

import SwiftUI
import AVFoundation

/// A view that provides the configuration interface for the app.
struct ConfigurationView: View {
    
    let sectionSpacing: CGFloat = 20
    @ObservedObject var camera: Camera
    
    var body: some View {
        Form {
            // Cameras heading
            Section(header: SectionHeader("Cameras")) {
                DevicePickerView(label: "Camera", devices: camera.videoDevices, selectedDevice: $camera.selectedVideoDevice)
                Picker("Formats", selection: $camera.selectedVideoFormat) {
                    ForEach(camera.videoFormats, id: \.id) {
                        Text($0.name).tag($0)
                    }
                }
                .labelsHidden()
                Toggle(isOn: $camera.isAutomaticCameraSelectionEnabled) {
                    Text("Automatic Camera Selection")
                }
            }

            Spacer().frame(height: sectionSpacing)
            
            // Microphones heading
            Section(header: SectionHeader("Microphones")) {
                DevicePickerView(label: "Microphone", devices: camera.audioDevices, selectedDevice: $camera.selectedAudioDevice)
            }

            Spacer().frame(height: sectionSpacing)
            
            // Video Effects heading
            Section(header: SectionHeader("Video Effects")) {
                Toggle(isOn: $camera.isCenterStageEnabled) {
                    Text("Center Stage")
                }
                .disabled(!camera.isCenterStageSupported)
                .padding(.bottom, 4)
                EffectStatusView(name: "Portrait Mode", status: camera.isPortraitEffectEnabled)
                    .disabled(!camera.isPortraitEffectSupported)
                EffectStatusView(name: "Studio Light", status: camera.isStudioLightEnabled)
                    .disabled(!camera.isStudioLightSupported)
            }
            Spacer()
        }
        .padding()
    }
}

struct ConfigurationView_Previews: PreviewProvider {
    class PreviewCamera: Camera {
        override func start() async { /* Overridden to do nothing */ }
    }
    static var previews: some View {
        ConfigurationView(camera: PreviewCamera())
    }
}

/// A view that displays a section header in the `ConfigurationView`.
struct SectionHeader: View {
    let title: String
    init(_ title: String) {
        self.title = title
    }
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
    }
}

/// A view that defines a drop-down menu of devices.
struct DevicePickerView: View {
    
    let label: String
    let devices: [Device]
    @Binding var selectedDevice: Device
    
    var body: some View {
        Picker(label, selection: $selectedDevice) {
            ForEach(devices, id: \.id) {
                Text($0.name).tag($0)
            }
        }
        .labelsHidden()
    }
}

/// A view that displays the enabled status of a system video effect.
struct EffectStatusView: View {
    
    let name: String
    let status: Bool
    
    @Environment(\.isEnabled) private var isViewEnabled: Bool
    
    var disabledColor: Color {
        Color(nsColor: NSColor.disabledControlTextColor)
    }
    
    var indicatorColor: Color {
        isViewEnabled ? (status ? .green : .gray) : disabledColor
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 14, height: 14)
            Text("\(name)")
                .font(.body)
                .foregroundColor(isViewEnabled ? .primary : disabledColor)
        }
    }
}

struct EffectStatusView_Previews: PreviewProvider {
    static var previews: some View {
        EffectStatusView(name: "Portrait mode", status: true)
            .frame(width: 450, height: 30, alignment: .leading)
            .disabled(true)
    }
}
