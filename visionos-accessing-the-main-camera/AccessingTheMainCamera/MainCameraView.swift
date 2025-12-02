/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the main camera feed from Apple Vision Pro.
*/

import SwiftUI

struct MainCameraView: View {
    @State private var sessionManager = CameraSessionManager()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            if CameraSessionManager.isSupported == false {
                ContentUnavailableView {
                    Label("Camera access isn't supported on this device.", systemImage: "camera")
                }
            } else if sessionManager.accessDenied {
                ContentUnavailableView {
                    Label("Camera access isn't allowed.", systemImage: "camera")
                }
                description: {
                    Text("Allow camera access in Settings.")
                }
            } else {
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Configuration")
                                Spacer()
                                Picker("Configuration", selection: $sessionManager.configuration) {
                                    ForEach(CameraSessionManager.CameraConfiguration.allCases, id: \.self) { configuration in
                                        Text(configuration.description)
                                    }
                                }
                            }
                            Toggle("High resolution", isOn: $sessionManager.isHighResolution)
                                
                        }
                        .frame(maxWidth: 400)
                        Spacer()
                    }
                    HStack {
                        CameraFrameView(preview: sessionManager.leftPreview)
                        CameraFrameView(preview: sessionManager.rightPreview)
                    }
                }
                .padding()
            }
        }
        .onChange(of: scenePhase) { oldScenePhase, newScenePhase in
            if oldScenePhase == .background {
                Task {
                    await sessionManager.restart()
                }
            }
        }
        .task {
            await sessionManager.run()
        }
    }
}
