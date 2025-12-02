/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents a video source that delivers video frames in real time.
*/

import AVFoundation

/// A type that reads video frames from a source movie file and delivers uncompressed frames one-by-one in real time in the specified pixel format.
public struct RealTimeVideoSource {
    fileprivate var videoSource: VideoSource
    
    /// Creates an instance of `RealTimeVideoSource`.
    /// - Parameters:
    ///   - filePath: Source movie file path.
    ///   - outputPixelFormat: Pixel format of the uncompressed output frames that `VideoSource` delivers.
    ///   - alwaysCopiesSampleData: A Boolean value that specifies whether to modify the output sample data.
    ///                             Set to `false` to not modify the output sample data; otherwise, set to `true`.
    public init(filePath: String, outputPixelFormat: OSType, alwaysCopiesSampleData: Bool) {
        videoSource = VideoSource(filePath: filePath, outputPixelFormat: outputPixelFormat, alwaysCopiesSampleData: alwaysCopiesSampleData)
    }

    /// Returns an async sequence with the maximum number of frames to deliver that you specify.
    public func frames(frameCount: Int = .max) -> RealTimeVideoSourceFrames {
        return RealTimeVideoSourceFrames(source: self, frameCount: frameCount)
    }

    /// A read-only property that respresents frame rate, video width, and height of the source movie file.
    public var sourceInfo: VideoSource.SourceInfo {
        get async throws {
            return try await videoSource.sourceInfo
        }
    }
}

/// An `AsyncSequence` that asynchronously delivers uncompressed frames.
public struct RealTimeVideoSourceFrames: AsyncSequence {
    public typealias Element = VideoSourceFrames.Element
    
    fileprivate let source: RealTimeVideoSource
    fileprivate let frameCount: Int
    
    /// Creates an instance of `RealTimeVideoSourceFrames`.
    /// - Parameters:
    ///   - source: A `RealTimeVideoSource` instance.
    ///   - frameCount: The maximum number of frames to deliver.
    fileprivate init(source: RealTimeVideoSource, frameCount: Int) {
        self.source = source
        self.frameCount = frameCount
    }

    /// A type that holds a timebase.
    private struct LazyState {
        fileprivate let deliveryQueue: DispatchQueue
        fileprivate let timebase: CMTimebase

        fileprivate init() throws {
            deliveryQueue = DispatchQueue(label: "delivery-queue")
            timebase = try CMTimebase(sourceClock: CMClock.hostTimeClock)
        }
    }

    /// An `AsyncIterator` that asynchronously delivers uncompressed frames.
    public struct AsyncIterator: AsyncIteratorProtocol {
        private let frameCount: Int
        private var lazyState: LazyState?
        private var sourceAsyncIterator: VideoSourceFrames.AsyncIterator

        /// Creates an instance of `AsyncIterator`.
        /// - Parameters:
        ///   - source: A `RealTimeVideoSource` instance.
        ///   - frameCount: The maximum number of frames to deliver.
        fileprivate init(source: RealTimeVideoSource, frameCount: Int) {
            self.frameCount = frameCount
            sourceAsyncIterator = source.videoSource.frames(frameCount: frameCount).makeAsyncIterator()
        }
        
        /// Delivers an uncompressed frame.
        /// - Returns: A tuple that contains an image buffer and presentation timestamp.
        public mutating func next() async throws -> (CVImageBuffer, CMTime)? {
            if let lazyState = self.lazyState {
                // `VideoSource` takes care of monitoring the frame count.
                guard let (imageBuffer, pts) = try await sourceAsyncIterator.next() else {
                    return nil
                }

                try await wait(until: pts, accordingTo: lazyState)

                return (imageBuffer, pts)
            } else {
                self.lazyState = try LazyState()
                return try await self.next()
            }
        }
        
        /// Waits until next presentation time in source movie timeline.
        /// - Parameters:
        ///   - deadline: The next presentation time.
        ///   - lazyState: A `LazyState` instance that contains a timebase.
        private func wait(until deadline: CMTime, accordingTo lazyState: LazyState) async throws {
            let timebase = lazyState.timebase
            let deliveryQueue = lazyState.deliveryQueue
            let timebaseTimer = DispatchSource.makeTimerSource(flags: [], queue: deliveryQueue)

            try await withCheckedThrowingContinuation { continuation in
                do {
                    timebaseTimer.setEventHandler {
                        continuation.resume()
                    }
                    timebaseTimer.activate()
                    try timebase.addTimer(timebaseTimer)
                    try timebase.setTimerNextFireTime(timebaseTimer, fireTime: deadline)

                    if timebase.rate != 1 {
                        try timebase.setTime(CMTime(seconds: 0, preferredTimescale: 600))
                        try timebase.setRate(1.0)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            timebaseTimer.cancel()
        }
    }

    /// Returns an async iterator.
    public func makeAsyncIterator() -> AsyncIterator {
        return AsyncIterator(source: self.source, frameCount: self.frameCount)
    }
}
