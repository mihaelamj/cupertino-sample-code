/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provide a button to start the reconstruction.
*/

import SwiftUI
import os

private let logger = Logger(subsystem: ObjectCaptureReconstructionApp.subsystem,
                            category: "ProcessButton")

struct ProcessButton: View {
    @Environment(AppDataModel.self) private var appDataModel: AppDataModel
    // Indicates if the button is pressed.
    @State private var processing = false

    var body: some View {
        HStack {
            Spacer()
            Button("Process") {
                if !processing {
                    processing = true
                    logger.log("Process button clicked!")
                    Task {
                        await appDataModel.startReconstruction()
                    }
                }
            }
            .disabled(processing)
        }
        .padding(.top, 3)
    }
}
