/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view that includes both the image capture and reconstruction.
*/

import SwiftUI

import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "PrimaryView")

struct PrimaryView: View {
    @Environment(AppDataModel.self) var appModel

    @State private var showReconstructionView: Bool = false
    @State private var showErrorAlert: Bool = false
    private var showProgressView: Bool {
        appModel.state == .completed || appModel.state == .restart || appModel.state == .ready
    }

    var body: some View {
        VStack {
            if appModel.state == .capturing {
                if let session = appModel.objectCaptureSession {
                    CapturePrimaryView(session: session)
                }
            } else if showProgressView {
                CircularProgressView()
            }
        }
        .onChange(of: appModel.state) { _, newState in
            if newState == .failed {
                showErrorAlert = true
                showReconstructionView = false
            } else {
                showErrorAlert = false
                showReconstructionView = newState == .reconstructing || newState == .viewing
            }
        }
        .sheet(isPresented: $showReconstructionView) {
            if let folderManager = appModel.captureFolderManager {
                ReconstructionPrimaryView(outputFile: folderManager.modelsFolder.appendingPathComponent("model-mobile.usdz"))
                    .interactiveDismissDisabled()
            }
        }
        .alert(
            "Failed:  " + (appModel.error != nil  ? "\(String(describing: appModel.error!))" : ""),
            isPresented: $showErrorAlert,
            actions: {
                Button("OK") {
                    logger.log("Calling restart...")
                    appModel.state = .restart
                }
            },
            message: {}
        )
    }
}

private struct CircularProgressView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack {
            Spacer()
            ZStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .light ? .black : .white))
                Spacer()
            }
            Spacer()
        }
    }
}

