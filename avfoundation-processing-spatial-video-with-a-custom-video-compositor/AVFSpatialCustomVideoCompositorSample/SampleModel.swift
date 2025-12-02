/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An observable model object that manages playback and export configuration.
*/

import os
import AVFoundation

@Observable
class SampleModel {
    
    /// The player instance.
    private(set) var player = AVPlayer()
    
    private var movieFile: URL? = nil
    private(set) var isMovieFileLoaded = false
    
    private var exporter: Exporter?
    private(set) var isExportInProgress = false
    private(set) var exportTempURL: URL? = nil
    
    /// A Boolean value that indicates whether the currently selected compositor
    /// requires the ability to preview stereo video.
    private(set) var previewRequiresStereo: Bool
    var canDevicePlayStereo: Bool {
#if os(visionOS)
        true
#else
        false
#endif
    }
    
    init() {
        // Set the initial state based on the user's compositor selection.
        previewRequiresStereo = UserSettings.shared.compositorType == .stereoOut
    }
    
    /// Loads a movie file from disk.
    /// - Parameter movieURL: The URL of the movie file to load.
    func loadMovieFile(_ movieURL: URL) {
        let oldMovieFile = movieFile
        movieFile = movieURL
        // Release access to the sandbox-scope URL.
        oldMovieFile?.stopAccessingSecurityScopedResource()
        // Make the specified URL accessible to the app process.
        guard movieURL.startAccessingSecurityScopedResource() else {
            logger.debug("Unable to gain access to movie file at \(movieURL.path())")
            return
        }
        logger.log("Will play \(movieURL.path())")
        Task {
            do {
                if previewRequiresStereo, !canDevicePlayStereo {
                    // Clear to the player queue if the selected compositor requires
                    // rendering stereo video, but the current platform doesn't support it.
                    player.replaceCurrentItem(with: nil)
                } else {
                    player = try await makePlayer(url: movieURL)
                }
                isMovieFileLoaded = true
            } catch {
                logger.error("Error: caught exception: \(error) ")
                isMovieFileLoaded = false
            }
        }
    }
    
    /// Applies the user's compositor selection to the app state.
    func applyUserSettings() {
        guard let movieFile else { return }
        previewRequiresStereo = UserSettings.shared.compositorType == .stereoOut
        Task {
            // Rebuild the player after modifying the user settings.
            player = try await makePlayer(url: movieFile)
        }
    }
    
    /// Exports the currently loaded movie using the specified exporter type.
    /// - Parameter exporterType: The type of exporter to use.
    func export(using exporterType: ExporterType) async throws {
        guard let movieFile else { return }
        
        // Create an exporter object for the specified type.
        exporter = exporterType.createExporter()
        isExportInProgress = true
        let asset = AVURLAsset(url: movieFile)
        let videoComposition = try await makeVideoComposition(for: asset)
        try await exporter?.export(asset: asset, videoComposition: videoComposition)
        if case .complete(let tempURL) = exporter?.status {
            exportTempURL = tempURL
        }
        isExportInProgress = false
        exporter = nil
    }
    
    /// The progress of the export operation, if any.
    var exportProgress: String? {
        switch exporter?.status {
        case .exporting(progress: let percentage):
            return String(format: "Exporting (%d%%)", Int(percentage * 100 + 0.5))
        default:
            return nil
        }
    }
    
    /// Creates a new player to play the movie at the specified URL.
    /// - Parameter url: The URL of the movie file to play.
    private func makePlayer(url: URL) async throws -> AVPlayer {
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        // Create a video composition for the user-selected custom compositor.
        if let videoComposition = try await makeVideoComposition(for: asset) {
            playerItem.videoComposition = videoComposition
            playerItem.seekingWaitsForVideoCompositionRendering = true
        }
        return AVPlayer(playerItem: playerItem)
    }
    
    /// Creates a video composition suitable for playing the specified movie asset.
    /// - Parameter asset: The movie asset to play.
    private func makeVideoComposition(for asset: AVAsset) async throws -> AVVideoComposition? {
        
        let compositorType = UserSettings.shared.compositorType
        guard compositorType != .none else {
            // Return nil if the user chooses not to use a video composition.
            return nil
        }
        // Return a video composition if the user selects the mono or stereo compositor in the settings view.
        return try await VideoCompositionBuilder(asset: asset, compositorType: compositorType).build()
    }
}
