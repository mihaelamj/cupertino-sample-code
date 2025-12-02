/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a picker for each device connected to Apple Vision Pro, and displays the selected device's video feed.
*/

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var deviceManager = DeviceManager()
    @State private var presentAccessDeniedAlert: Bool = false
    
    var body: some View {
        let selectedDevice = deviceManager.selectedDevice
        let devices = deviceManager.devices

        VStack {
            Picker("Device Picker", selection: $deviceManager.selectedDevice) {
                Text("Select Device").tag(nil as Device?)
                ForEach(devices) {
                    Text($0.name).tag($0)
                }
            }
            .disabled(deviceManager.initialAuthorizationStatus != .authorized)
            
            DevicePreview(preview: deviceManager.preview)
                .task {
                    await deviceManager.start()
                }
                .overlay {
                    if selectedDevice == nil {
                        ContentUnavailableView {
                             Label("No Device", systemImage: "camera")
                        }
                         description: {
                             Text("Select a device.")
                        }
                    }
                }
        }
        .onChange(of: devices) {
            let isSelectedDeviceInDevices = devices.contains(where: { $0 == selectedDevice })
            
            if isSelectedDeviceInDevices == false {
                deviceManager.selectedDevice = nil
            }
        }
        .onChange(of: deviceManager.initialAuthorizationStatus, initial: true) {
            presentAccessDeniedAlert = deviceManager.initialAuthorizationStatus == .denied
        }
        .alert("Enable camera access in Settings and reopen the app.", isPresented: $presentAccessDeniedAlert) {
            Button("Exit app", role: .cancel) {
                exit(EXIT_SUCCESS)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
