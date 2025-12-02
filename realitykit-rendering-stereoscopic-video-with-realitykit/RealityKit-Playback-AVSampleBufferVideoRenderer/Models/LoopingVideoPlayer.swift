/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A looping video player.
*/

import AVFoundation

/// A looping video player.
final class LoopingVideoPlayer {
    /// The synchronizer that controls the underlying video renderer.
    private let synchronizer = AVSampleBufferRenderSynchronizer()
    
    /// The video renderer that enqueues individual frames for playback.
    let videoRenderer = AVSampleBufferVideoRenderer()
    
    /// A representation of the video asset that the app plays.
    private let asset: AVURLAsset
    
    /// A reference to the processor that the system uses during the next playback loop.
    private var nextProcessor: SerialProcessor?
    
    /// A Boolean value that indicates whether the player is currently looping.
    private var isLooping = false

    /// A property that counts the number of playback loops.
    private var loopCount = 0

    // MARK: Internal behavior

    /// Initializes a player with the specified asset URL.
    /// - Parameter assetURL: A URL for the asset that the app plays.
    init(assetURL: URL) {
        synchronizer.addRenderer(videoRenderer)
        asset = AVURLAsset(url: assetURL)
    }
    
    /// Begin loading the player.
    func load() async throws {
        // Determine the duration of the underlying video asset.
        let duration = try await asset.load(.duration)

        // Use the asset duration as the boundary period with which to loop.
        synchronizer.addBoundaryTimeObserver(forTimes: [NSValue(time: duration)], queue: nil) {
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.loop(rate: self.synchronizer.rate)
            }
        }

        // Prepare the processor that the app uses for the initial playback loop.
        enqueueProcessor()
    }
    
    /// Begin playback by starting the loop.
    func play() {
        isLooping = true
        loop(rate: 1)
    }
    
    /// End playback by stopping the loop and resetting relevant state.
    func stop() {
        nextProcessor = nil
        isLooping = false
        loopCount = 0
        synchronizer.rate = 0
        videoRenderer.stopRequestingMediaData()
    }

    // MARK: Private behavior

    /// Prepares a processor instance for the next playback loop.
    private func enqueueProcessor() {
        nextProcessor = SerialProcessor(videoRenderer: videoRenderer, asset: asset)
    }
    
    /// Executes a logical playback loop.
    /// - Parameter rate: The rate with which to playback content.
    private func loop(rate: Float) {
        guard isLooping, let nextProcessor else {
            return
        }

        let currentProcessor = nextProcessor
        process(with: currentProcessor)
        synchronizer.setRate(rate, time: .zero)

        enqueueProcessor()
        loopCount += 1
    }
    
    /// Executes a given serial processor.
    /// - Parameter processor: The processor to execute.
    private func process(with processor: SerialProcessor) {
        Task {
            do {
                try await processor.process()
            } catch {
                debugPrint("\(#function) — error encountered during processing: \(error.localizedDescription)")
                stop()
            }
        }
    }
}
