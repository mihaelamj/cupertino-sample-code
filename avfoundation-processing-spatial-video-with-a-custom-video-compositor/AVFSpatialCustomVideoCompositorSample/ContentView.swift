/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main user interface.
*/

import os
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {

    @State private var sampleModel = SampleModel()
    @State private var isShowingFileImport = false
    @State private var isShowingSettings = false
    @State private var isShowingFileMover = false
    @State private var coverData: CoverData? = nil
    @State private var exporterType: ExporterType = .exportSession

    var body: some View {
        NavigationStack {
            VStack() {
                // "Load movie..." button
                HStack(alignment: .center) {
                    Button {
                        isShowingFileImport.toggle()
                    } label: {
                        Text("Load movie...")
                    }
                    .buttonStyle(.bordered)
                    .fileImporter(isPresented: $isShowingFileImport, allowedContentTypes: [.item]) { results in
                        switch results {
                        case .success(let movieURL):
                            sampleModel.loadMovieFile(movieURL)
                            if sampleModel.isMovieFileLoaded {
                                coverData = CoverData(body: "Custom data")
                            }
                        case .failure(let error):
                            logger.error("\(error)")
                        }
                    }
                }
                if sampleModel.isMovieFileLoaded {
                    // Export picker and button.
                    HStack {
                        Picker("Exporter:", selection: $exporterType) {
                            ForEach(ExporterType.allCases, id: \.self) { exporterType in
                                Text(exporterType.description)
                                    .tag(exporterType)
                            }
                        }
                        .pickerStyle(.automatic)
                        .labelsHidden()
                        Button {
                            Task {
                                try await sampleModel.export(using: exporterType)
                                isShowingFileMover.toggle()
                            }
                        } label: {
                            if !sampleModel.isExportInProgress {
                                Text("Export")
                            } else {
                                Text(sampleModel.exportProgress ?? "Export")
                            }
                        }
                        .disabled(sampleModel.isExportInProgress)
                        .disabled(!sampleModel.isMovieFileLoaded)
                    }
                    .fileMover(isPresented: $isShowingFileMover, file: sampleModel.exportTempURL) { result in
                        switch result {
                        case .success(let url):
                            logger.log("moved to \(url)")
                        case .failure(let error):
                            logger.log("failed to move. error: \(error)")
                        }
                    }

                    // The player view
                    #if os(visionOS)
                        Button("Show movie player") {
                            coverData = CoverData(body: "Custom Data")
                        }
                        // A player view can't display stereo video when embedded in the main UI.
                        // Instead, present it in an "expanded" state by opening a dedicated window.
                        .fullScreenCover(item: $coverData) { details in
                            VStack() {
                                PlayerView(player: sampleModel.player)
                            }
                            .onTapGesture {
                                coverData = nil
                            }
                        }
                    #else
                    // iOS and macOS can export stereo video, but aren't able to render it,
                    // so hide the player when you select the stereo compositor in settings.
                    if sampleModel.previewRequiresStereo {
                        Text("This platform doesn't support previewing stereo video.")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.black)
                    } else {
                        PlayerView(player: sampleModel.player)
                    }
                    #endif
                }
            }
            .sheet(isPresented: $isShowingSettings, onDismiss: didDismissSettings) {
                SettingsView()
            }
            .toolbar {
                Button("Settings") {
                    isShowingSettings.toggle()
                }
            }
        }
    }

    func didDismissSettings() {
        sampleModel.applyUserSettings()
    }
}

#Preview {
    ContentView()
}

struct CoverData: Identifiable {
    var id: String {
        return body
    }
    let body: String
}
