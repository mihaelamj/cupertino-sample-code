/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app class.
*/

import SwiftUI
import RealityKit

import CompositorServices

import ModelIO
import ARKit
@preconcurrency import MetalKit

import os.log

var globalAppModel = AppModel()

@main
struct CompositorServicesHoverEffectApp: App {
    @State var appModel = globalAppModel
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some SwiftUI.Scene {
        WindowGroup {
            if appModel.isImmersiveSpaceOpen {
                Button("Close Immersive Space") {
                    appModel.isImmersiveSpaceOpen = false
                    Task { await dismissImmersiveSpace() }
                }.padding()
            } else {
                VStack {
                    SettingsView(appModel: $appModel)
                    Button("Open Immersive Space") {
                        Task {
                            let result = await openImmersiveSpace(id: AppModel.immersiveSpaceId)
                            switch result {
                            case .opened:
                                appModel.isImmersiveSpaceOpen = true
                            case .userCancelled:
                                logger.log(level: .info, "User cancelled opening the immersive space")
                            case .error:
                                logger.log(level: .error, "Error opening the immersive space")
                            @unknown default:
                                logger.log(level: .error, "Unknown result opening the immersive space")
                            }
                        }
                    }
                }.padding()
            }
        }.defaultSize(CGSize(width: 500, height: 300))

        #if os(macOS)
        RemoteImmersiveSpace(id: AppModel.immersiveSpaceId) {
            MacOSLayer { remoteDeviceIdentifier in
                makeCompositorLayer(CompositorLayerContext(
                    remoteDeviceIdentifier: remoteDeviceIdentifier
                ))
            }
        }
        .immersionStyle(selection: .constant(.full), in: .full)
        #else
        ImmersiveSpace(id: AppModel.immersiveSpaceId) {
            makeCompositorLayer(.init())
        }
        .immersionStyle(selection: .constant(.full), in: .full)
        #endif
    }
}

#if os(macOS)
struct MacOSLayer: CompositorContent {
    @Environment(\.remoteDeviceIdentifier)
    private var remoteDeviceIdentifier: RemoteDeviceIdentifier?

    let closure: (RemoteDeviceIdentifier?) -> CompositorLayer

    var body: some CompositorContent {
        closure(remoteDeviceIdentifier)
    }
}
#endif
