/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents a video source that encapsulates an asset reader
        and reads uncompressed video frames from an input movie file.
*/

import AVFoundation

/// A type that reads video frames from a source movie file and delivers uncompressed frames one-by-one in the specified pixel format.
public struct VideoSource {
    /// The source movie file path.
    public let filePath: String

    /// The pixel format in which to deliver uncompressed frames.
    public let outputPixelFormat: OSType

    // Set to `false` to not modify the output `CVImageBuffer` sample data; otherwise, set to `true`.
    public let alwaysCopiesSampleData: Bool

    public struct SourceInfo: Sendable {
        /// The nominal video frame rate of the source movie file.
        public var frameRate: Float

        /// The video width of the source movie file.
        public var width: Int

        /// The video height of the source movie file.
        public var height: Int
    }

    fileprivate let sourceAsset: AVAsset

    /// Creates an instance of `VideoSource`.
    /// - Parameters:
    ///   - filePath: The source movie file path.
    ///   - outputPixelFormat: The pixel format of the uncompressed output frames that `VideoSource` delivers.
    ///   - alwaysCopiesSampleData: A Boolean value that specifies whether to modify the output sample data.
    ///                             Set to `false` to not modify the output sample data; otherwise, set to `true`.
    public init(filePath: String, outputPixelFormat: OSType, alwaysCopiesSampleData: Bool) {
        self.filePath = filePath
        self.outputPixelFormat = outputPixelFormat
        self.alwaysCopiesSampleData = alwaysCopiesSampleData

        let sourceURL = URL(fileURLWithPath: filePath)
        self.sourceAsset = AVURLAsset(url: sourceURL)
    }

    /// Returns an async sequence with the maximum number of frames to deliver that you specify.
    public func frames(frameCount: Int = .max) -> VideoSourceFrames {
        return VideoSourceFrames(source: self, frameCount: frameCount)
    }

    /// A read-only property that respresents frame rate, video width, and height of the source movie file.
    public var sourceInfo: SourceInfo {
        get async throws {
            let videoTrack = try await self.sourceTrack
            let frameRate = try await videoTrack.load(.nominalFrameRate)
            let formatDescArray = try await videoTrack.load(.formatDescriptions)
            let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescArray[0])

            return SourceInfo(frameRate: frameRate, width: Int(dimensions.width), height: Int(dimensions.height))
        }
    }

    /// The first video track of the source movie file.
    fileprivate var sourceTrack: AVAssetTrack {
        get async throws {
            let sourceMovieVideoTracks = try await sourceAsset.loadTracks(withMediaType: .video)
            guard let videoTrack = sourceMovieVideoTracks.first else {
                throw RuntimeError("\"\(filePath)\" has no video track!")
            }
            return videoTrack
        }
    }
}

/// An `AsyncSequence` instance that asynchronously delivers uncompressed frames.
public struct VideoSourceFrames: AsyncSequence {
    public typealias Element = (CVImageBuffer, CMTime)

    fileprivate let source: VideoSource
    fileprivate let frameCount: Int
    
    /// Creates an instance of `VideoSourceFrames`.
    /// - Parameters:
    ///   - source: A `VideoSource` instance.
    ///   - frameCount: The maximum number of frames to deliver.
    fileprivate init(source: VideoSource, frameCount: Int) {
        self.source = source
        self.frameCount = frameCount
    }
    
    /// A buffer queue that buffers uncompressed video frames read from the source movie file.
    private class SampleBufferQueue: @unchecked Sendable {
        /// The size of the buffer queue.
        private let maxFramesInQueue = 3
        
        /// A countable semaphore that indicates the number of free spaces in the buffer queue.
        private let enqueueSemaphore: Semaphore
        
        /// A binary semaphore that indicates if the buffer queue isn't empty.
        private let dequeueSemaphore: Semaphore
        
        /// A binary semaphore that delays dequeue at start until the buffer queue is filled.
        private let bufferKickOffSemaphore: Semaphore

        /// A dispatch queue that protects the buffer queue state.
        private let bufferQueue: DispatchQueue

        /// An array of uncompressed video frames that implements the buffer queue.
        private var bufferArray: [CMSampleBuffer]
        
        /// A Boolean value that specifies whether dequeue can start.
        private var bufferKickedOff: Bool = false
        
        /// A Boolean value that specifies whether the end of the video track is reached in the source movie file.
        private var endOfTrack: Bool = false
        
        /// Creates an instance of `SampleBufferQueue`.
        /// - Parameters:
        ///   - sourceAsset: The source `AVAsset` from which to read video frames.
        ///   - videoTrack: The source `AVAssetTrack` from which to read video frames.
        ///   - outputPixelFormat: The pixel format of output uncompressed video frames.
        ///   - alwaysCopiesSampleData: A Boolean value that specifies whether to modify the output sample data.
        ///                             Set to `false` to not modify the output sample data; otherwise, set to `true`.
        ///   - frameCount: The maximum number of frames to read from source `AVAsset` instance.
        fileprivate init(sourceAsset: AVAsset,
                         videoTrack: AVAssetTrack,
                         outputPixelFormat: OSType,
                         alwaysCopiesSampleData: Bool,
                         frameCount: Int) async throws {
            enqueueSemaphore = Semaphore(value: maxFramesInQueue, name: "sem-enq")
            dequeueSemaphore = Semaphore(value: 0, name: "sem-deq")
            bufferKickOffSemaphore = Semaphore(value: 0, name: "sem-kickoff")
            bufferQueue = DispatchQueue(label: "buffer-queue")
            bufferArray = []

            let assetReader = try AVAssetReader(asset: sourceAsset)
            let pixelBufferAttributes: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: outputPixelFormat as CFNumber]
            let trackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: pixelBufferAttributes)

            trackOutput.alwaysCopiesSampleData = alwaysCopiesSampleData
            assetReader.add(trackOutput)

            guard assetReader.startReading() else {
                assert(assetReader.status == .failed)
                throw assetReader.error!
            }

            Task {
                for frameIndex in 0..<frameCount {
                    if frameIndex == maxFramesInQueue {
                        bufferQueue.sync {
                            bufferKickedOff = true
                        }
                        await bufferKickOffSemaphore.signal()
                    }
                    guard let sbuf = trackOutput.copyNextSampleBuffer() else {
                        guard assetReader.status == .completed else {
                            assert(assetReader.status == .failed)
                            print("Frame read failed. (\(assetReader.error!))")
                            break
                        }

                        bufferQueue.sync {
                            endOfTrack = true
                        }
                        await dequeueSemaphore.signal()
                        break
                    }

                    await enqueue(sbuf)
                }

                bufferQueue.sync {
                    bufferKickedOff = true
                }
                await bufferKickOffSemaphore.signal()
            }
        }
        
        /// Enqueues a `CMSampleBuffer` to the buffer queue.
        /// - Parameter sbuf: An uncompressed video frame in a `CMSampleBuffer` instance read from the source movie file.
        private func enqueue(_ sbuf: CMSampleBuffer) async {
            await enqueueSemaphore.wait()

            var unblockDequeue = false
            bufferQueue.sync {
                bufferArray.append(sbuf)
                if bufferArray.count == 1 { unblockDequeue = true }
            }

            if unblockDequeue {
                await dequeueSemaphore.signal()
            }
        }
        
        /// Dequeues a sample buffer from the buffer queue.
        /// - Returns: A sample buffer, or `nil` once it delivers all requested frames or reaches the end of movie file,
        ///             whichever comes first.
        fileprivate func dequeue() async -> CMSampleBuffer? {
            var waitUntilBufferKickOff = true
            var isTrackEnded = false
            var waitBeforeDequeue = false

            bufferQueue.sync {
                if bufferKickedOff { waitUntilBufferKickOff = false }
                if bufferArray.isEmpty {
                    if endOfTrack {
                        isTrackEnded = true
                    } else {
                        waitBeforeDequeue = true
                    }
                }
            }

            if waitUntilBufferKickOff { await bufferKickOffSemaphore.wait() }
            if isTrackEnded { return nil }
            if waitBeforeDequeue { await dequeueSemaphore.wait() }

            var sbuf: CMSampleBuffer?
            bufferQueue.sync {
                if !bufferArray.isEmpty {
                    sbuf = bufferArray.removeFirst()
                }
            }

            if sbuf != nil {
                await enqueueSemaphore.signal()
            }

            return sbuf
        }
    }

    private actor Semaphore {
        private let name: String
        private var continuationArray: [CheckedContinuation<Void, Never>]
        private var value: Int

        fileprivate var description: String {
            return "Semaphore[" + name + "]" + " value=\(value)"
        }

        fileprivate init(value: Int, name: String) {
            self.name = name
            self.value = value
            continuationArray = []
        }

        fileprivate func wait() async {
            value -= 1
            if value < 0 {
                await withCheckedContinuation {
                    continuationArray.append($0)
                }
            }
        }

        fileprivate func signal() {
            value += 1
            if !continuationArray.isEmpty {
                continuationArray.removeFirst().resume()
            }
        }
    }

    /// An `AsyncIterator` instance that asynchronously delivers uncompressed frames.
    public struct AsyncIterator: AsyncIteratorProtocol {
        private let source: VideoSource
        private let frameCount: Int
        private var framesEmitted = 0
        private var sampleBufferQueue: SampleBufferQueue?

        /// Creates an instance of `AsyncIterator`.
        /// - Parameters:
        ///   - source: A `VideoSource` instance.
        ///   - frameCount: The maximum number of frames to deliver.
        fileprivate init(source: VideoSource, frameCount: Int) {
            self.source = source
            self.frameCount = frameCount
        }

        /// Delivers an uncompressed frame.
        /// - Returns: A tuple that contains an image buffer and presentation time stamp.
        public mutating func next() async throws -> (CVImageBuffer, CMTime)? {
            if let sampleBufferQueue = self.sampleBufferQueue {
                guard framesEmitted < self.frameCount else { return nil }
                guard let sbuf = await sampleBufferQueue.dequeue() else {
                    return nil
                }
                guard let imageBuffer = sbuf.imageBuffer else {
                    return nil
                }

                framesEmitted += 1

                return (imageBuffer, sbuf.presentationTimeStamp)
            } else {
                let sampleBufferQueue = try await SampleBufferQueue(sourceAsset: source.sourceAsset,
                                                                    videoTrack: try await source.sourceTrack,
                                                                    outputPixelFormat: source.outputPixelFormat,
                                                                    alwaysCopiesSampleData: source.alwaysCopiesSampleData,
                                                                    frameCount: self.frameCount)

                self.sampleBufferQueue = sampleBufferQueue

                return try await self.next()
            }
        }
    }
    
    /// Returns an async iterator.
    public func makeAsyncIterator() -> AsyncIterator {
        return AsyncIterator(source: self.source, frameCount: self.frameCount)
    }
}
