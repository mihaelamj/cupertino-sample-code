/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements `VideoPreviewView` to show the current video progress.
*/

import SwiftUI
import AVKit
import OSLog

struct VideoPreviewView: View {

    @Environment(VideoProcessorModel.self) private var model
    @State private var isTargeted = false

    var body: some View {

        VStack {

            switch model.state {

            case .idle:

                ChooseVideoEffectView()

            case .ready(let inputURL):

                InputVideoView(inputURL: inputURL)

            case .processing:

                ProcessingVideoView()

            case .completed(let outputURL):

                OutputVideoView(outputURL: outputURL)

            case .failed(let error):

                ProcessingFailedView(error: error)
            }
        }
    }
}

struct ChooseVideoEffectView: View {

    @State private var isTargeted = false

    var body: some View {

        Text("Choose a Video Effect")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct InputVideoView: View {

    let inputURL: URL

    @Environment(VideoProcessorModel.self) private var model

    var body: some View {

        VStack {

            HStack(spacing: 20.0) {

                Text("Input Video")
                    .font(.largeTitle)

                Spacer()

                OpenQuickTimeButton(url: inputURL)
            }
            .padding()

            let player = AVPlayer(url: inputURL)
            VideoPlayer(player: player)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .dropDestination(for: URL.self) { items, _ in
                    if let sourceURL = items.first {
                        model.setState(.ready(inputURL: sourceURL))
                    }
                    return true
                }
        }
    }
}

struct OutputVideoView: View {

    let outputURL: URL

    var body: some View {

        VStack {

            HStack(spacing: 20.0) {

                Text("Output Video")
                    .font(.largeTitle)

                Spacer()

                SaveVideoButton(url: outputURL)

                OpenQuickTimeButton(url: outputURL)

                CloseButton()
            }
            .padding()

            let player = AVPlayer(url: outputURL)
            VideoPlayer(player: player)
        }
    }
}

struct ProcessingFailedView: View {

    let error: Error

    @Environment(VideoProcessorModel.self) private var model

    var body: some View {

        VStack {

            HStack(spacing: 20.0) {

                Text("Processing Failed")
                    .font(.largeTitle)

                let fault = error as CustomDebugStringConvertible

                Text(fault.debugDescription)
                    .font(.subheadline)

                Spacer()

                CloseButton()
            }
            .padding()

            Spacer()
        }
    }
}

struct ProcessingVideoView: View {

    @Environment(VideoProcessorModel.self) private var model
    @Environment(VideoProcessor.self) private var processor

    var body: some View {

        VStack {
            if model.selectedVideoEffect?.showProgress ?? false {

                HStack(spacing: 20.0) {

                    Text("Processing...")
                        .font(.largeTitle)

                    Spacer()

                    if case .processing(let progress) = model.state {
                        ProgressView(value: progress)
                    }
                }
                .padding()
            }

            if processor.aspectRatio >= 1.0 {
                VStack {

                    if let inputPreviewStream = processor.inputPreviewStream {
                        AVSampleBufferView(inputStream: inputPreviewStream)
                    }

                    if let outputPreviewStream = processor.outputPreviewStream {
                        AVSampleBufferView(inputStream: outputPreviewStream)
                    }
                }

            } else {
                HStack {

                    if let inputPreviewStream = processor.inputPreviewStream {
                        AVSampleBufferView(inputStream: inputPreviewStream)
                    }

                    if let outputPreviewStream = processor.outputPreviewStream {
                        AVSampleBufferView(inputStream: outputPreviewStream)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)    }
}

struct SaveVideoButton: View {

    let url: URL

    @State private var isSaving: Bool = false

    var body: some View {
        Button {
            isSaving = true
        } label: {
            VStack {
                Image(systemName: "square.and.arrow.down")
                    .imageScale(.large)

                Text("Save Video")
            }
        }
        .buttonStyle(.plain)
        .fileExporter(isPresented: $isSaving,
                      document: MovieDocument(url: url),
                      defaultFilename: "ProcessedVideo") { result in
            if case .success(let url) = result {
                logger.info("Exported to: \(url)")
            } else if case .failure(let error) = result {
                logger.error("Error exporting: \(error)")
            }
            isSaving = false
        }
        .fileDialogDefaultDirectory(URL.desktopDirectory)
    }

    struct MovieDocument: FileDocument {

        static var readableContentTypes: [UTType] { [.quickTimeMovie] }
        static var writableContentTypes: [UTType] { [.quickTimeMovie] }

        let url: URL

        init(url: URL) {
            self.url = url
        }

        init(configuration: ReadConfiguration) throws { throw Fault.unimplemented }

        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            try FileWrapper(url: url, options: .immediate)
        }
    }
    enum Fault: Error {
        case unimplemented
    }
}

struct OpenQuickTimeButton: View {

    let url: URL

    var body: some View {
        Button {
            Task.detached {
                NSWorkspace.shared.open(url)
            }
        } label: {
            VStack {
                Image(systemName: "play.rectangle.on.rectangle")
                    .imageScale(.large)

                Text("Open in QuickTime")
            }
        }
        .buttonStyle(.plain)
    }

}

struct OpenButton: View {

    @Environment(VideoProcessorModel.self) private var model
    @State private var isImporting: Bool = false

    var body: some View {
        Button {
            isImporting = true
        } label: {
            VStack {
                Image(systemName: "film")
                    .imageScale(.large)

                Text("Open Video")
            }
        }
        .buttonStyle(.plain)
        .fileImporter(isPresented: $isImporting,
                      allowedContentTypes: [.movie],
                      onCompletion: { result in

            switch result {
            case .success(let url):
                model.setState(.ready(inputURL: url))
            case .failure(let error):
                logger.error("Open Video failed with: \(error)")
            }
        })
        .fileDialogDefaultDirectory(defaultDirectory)

    }
    private var defaultDirectory: URL {
        let embeddedAssetsURL = Bundle.main.url(forResource: "EmbeddedAssets", withExtension: "")!

        let assetCount = (try? FileManager.default.contentsOfDirectory(at: embeddedAssetsURL,
                                                                       includingPropertiesForKeys: nil).count) ?? 0
        if assetCount > 0 {
            return embeddedAssetsURL
        } else {
            return URL.desktopDirectory
        }
    }
}

struct CloseButton: View {

    @Environment(VideoProcessorModel.self) private var model

    var body: some View {
        Button {

            if let effect = model.selectedVideoEffect,
               let url = effect.assetURL {
                model.selectedVideoEffect = effect
                model.setState(.ready(inputURL: url))
            } else {
                model.selectedVideoEffect = nil
                model.setState(.idle)
            }

        } label: {
            VStack {
                Image(systemName: "xmark.square")
                    .imageScale(.large)

                Text("Close")
            }
        }
        .buttonStyle(.plain)
    }
}

