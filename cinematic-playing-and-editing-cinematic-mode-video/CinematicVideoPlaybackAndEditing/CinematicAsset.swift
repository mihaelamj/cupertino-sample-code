/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main data model of the app.
*/

import SwiftUI
import AVFoundation
import Photos
import Cinematic

struct CinematicAsset: Identifiable {
    /// A unique identifier for this asset.
    let id = UUID()

    /// The local identifier used to fetch a `PHAsset`.
    let localIdentifier: String

    let pathComponent: String

    let player: AVPlayer

    /// Holds the Cinematic-specific asset data.
    let cinematicAssetData: CinematicAssetData

    /// The timestamp that corresponds to the time that was used to generate the `editImage` from the asset.
    var currentEditTime: CMTime = .zero

    /// A normalized timeline position that corresponds to the `currentEditTime`.
    var editTimelinePosition = Double.zero

    /// The current `fNumber` used to render the asset.
    var fNumber: Float

    /// Initializes the `CinematicAsset` using the `localIdentifier` of an underlying `PHAsset`.
    init?(localIdentifier: String) async {

        // Store the `localIdentifier`.
        self.localIdentifier = localIdentifier

        // Create a unique identifier that is suitable as a `pathComponent`.
        pathComponent = localIdentifier.replacingOccurrences(of: "/", with: "_")

        // Fetch the underlying `PHAsset` using the `localIdentifier`.
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)

        // Make sure there is a `PHAsset`; otherwise, return `nil`.
        guard let phAsset = result.firstObject else { return nil }

        // Create options to request the `AVAsset`.
        let videoRequestOptions = PHVideoRequestOptions()
        videoRequestOptions.version = .original
        videoRequestOptions.deliveryMode = .highQualityFormat
        videoRequestOptions.isNetworkAccessAllowed = true

        // Request the `AVAsset` asynchronously.
        let asset = await withCheckedContinuation { continuation in
            PHImageManager.default().requestAVAsset(forVideo: phAsset, options: videoRequestOptions) { avAsset, _, _ in
                continuation.resume(returning: avAsset)
            }
        }

        // If the `AVAsset` is `nil`, return `nil`.
        guard let asset else { return nil }

        do {
            cinematicAssetData = try await CinematicAsset.loadData(from: asset, pathComponent: pathComponent)
        } catch {
            print("Failed to load cinematic asset: \(error.localizedDescription)")
            return nil
        }

        // Set the initial `fNumber` to the `fNumber` of the loaded cinematic script.
        fNumber = cinematicAssetData.script.fNumber

        // Create compositions for the player item.
        do {
            let (avComposition, videoComposition) = cinematicAssetData.makeVideoComposition()

            let playerItem = AVPlayerItem(asset: avComposition)

            playerItem.videoComposition = videoComposition

            player = AVPlayer(playerItem: playerItem)
        }
    }

    /// Load cinematic asset data from the `AVAsset`.
    static private func loadData(from asset: AVAsset, pathComponent: String) async throws -> CinematicAssetData {
        // Load cinematic asset info from the `AVAsset`.
        let cinematicAssetInfo = try await CNAssetInfo(asset: asset)

        // Load the cinematic rendering session attributes from the asset.
        let renderingSessionAttributes = try await CNRenderingSession.Attributes(asset: asset)

        // Create a command queue for the rendering session.
        guard let renderingCommandQueue = MTLCreateSystemDefaultDevice()?.makeCommandQueue() else {
            fatalError("Couldn't create command queue")
        }

        // Create a cinematic rendering session using the command queue and session attributes.
        // Select an appropriate quality level for your use case.
        // Use `preferredTransform` for the display orientation of video.
        // The render size of the composition needs to be set accordingly.
        let renderingSession = CNRenderingSession(commandQueue: renderingCommandQueue,
                                                  sessionAttributes: renderingSessionAttributes,
                                                  preferredTransform: cinematicAssetInfo.preferredTransform,
                                                  quality: CNRenderingQuality.export)

        // Load the cinematic script from the asset.
        let cinematicScript = try await CNScript(asset: asset)

        // Load any cinematic script changes that may have been saved previously for this asset.
        let url = try FileManager.default.url(for: .applicationSupportDirectory,
                                              in: .userDomainMask, appropriateFor: nil,
                                              create: false)
        let fileURL = url.appendingPathComponent(pathComponent, conformingTo: .archive)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            // Read and load the changes.
            let scriptFileData = try Data(contentsOf: fileURL)
            let cinematicScriptChanges = CNScript.Changes(dataRepresentation: scriptFileData)
            cinematicScript.reload(changes: cinematicScriptChanges)
        }

        let nominalFrameRate = try await cinematicAssetInfo.frameTimingTrack.load(.nominalFrameRate)
        let naturalTimeScale = try await cinematicAssetInfo.frameTimingTrack.load(.naturalTimeScale)

        let cinematicAssetData = CinematicAssetData(avAsset: asset,
                                                    assetInfo: cinematicAssetInfo,
                                                    renderingSessionAttributes: renderingSessionAttributes,
                                                    renderingSession: renderingSession,
                                                    commandQueue: renderingCommandQueue,
                                                    script: cinematicScript,
                                                    nominalFrameRate: nominalFrameRate,
                                                    naturalTimeScale: naturalTimeScale)
        
        return cinematicAssetData
    }
}
