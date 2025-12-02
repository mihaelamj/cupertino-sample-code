/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This type processes video content serially.
*/

import AVFoundation
import CoreMedia
import CoreVideo
import Synchronization
import VideoToolbox

/// This type processes video content serially.
final class SerialProcessor {
    /// The video renderer to use during processing.
    private let videoRenderer: AVSampleBufferVideoRenderer
    
    /// The video asset to be processed.
    private let asset: AVURLAsset
    
    /// The prevailing stereo metadata.
    private let stereoMetadata: StereoMetadata
    
    /// A Boolean value that indicates whether or not processing is in progress.
    private var isProcessing = false

    // MARK: Internal behavior

    /// Initializes with the dependencies necessary for processing.
    /// - Parameters:
    ///   - videoRenderer: The video renderer.
    ///   - asset: The video asset.
    ///   - stereoMetadata: The applicable stereo metadata.
    init(
        videoRenderer: AVSampleBufferVideoRenderer,
        asset: AVURLAsset,
        stereoMetadata: StereoMetadata = .default
    ) {
        self.videoRenderer = videoRenderer
        self.asset = asset
        self.stereoMetadata = stereoMetadata
    }
    
    /// Begin processing.
    func process() async throws {
        // Load the asset.
        guard let videoTrack = try await asset.loadTracks(withMediaCharacteristic: .visual).first else {
            fatalError("Error loading side-by-side video input")
        }

        // Determine the size of the video track, which reflects frame packing.
        let videoFrameSize = try await videoTrack.load(.naturalSize)

        // Setup the pixel transfer session.
        var transferSession: VTPixelTransferSession?
        let sessionResult = VTPixelTransferSessionCreate(
            allocator: kCFAllocatorDefault,
            pixelTransferSessionOut: &transferSession
        )
        guard sessionResult == kCVReturnSuccess, let transferSession else {
            fatalError("Failed to create pixel transfer session: \(sessionResult)")
        }
        VTSessionSetProperty(transferSession, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_CropSourceToCleanAperture)

        // Setup the pixel buffer pool.
        let eyeFrameSize = CVImageSize(
            width: Int(videoFrameSize.width / stereoMetadata.horizontalScale),
            height: Int(videoFrameSize.height / stereoMetadata.verticalScale)
        )
        let defaultAttributes = CVPixelBufferCreationAttributes(
            pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
            size: eyeFrameSize
        )
        let recommendedAttributes = videoRenderer.recommendedPixelBufferAttributes
        guard let mergedAttributes = CVPixelBufferAttributes(merging: [CVPixelBufferAttributes(defaultAttributes), recommendedAttributes]),
              let creationAttributes = CVPixelBufferCreationAttributes(mergedAttributes),
              let pixelBufferPool = try? CVMutablePixelBuffer.Pool(pixelBufferAttributes: creationAttributes)
        else {
            fatalError("Failed to create pixel buffer pool")
        }

        // Setup the asset reader.
        let readerSettings: [String: Any] = [
            kCVPixelBufferIOSurfacePropertiesKey as String: [String: String]()
        ]
        let videoTrackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerSettings)
        let assetReader = try AVAssetReader(asset: asset)
        let videoTrackOutputProvider = assetReader.outputProvider(for: videoTrackOutput)
        try assetReader.start()
        
        Task {
            // Prepare the renderer for processing.
            await untilReadyForMoreMediaData()
            isProcessing = true

            // Process all read frames from the input video track.
            while videoRenderer.isReadyForMoreMediaData && isProcessing {
                while let sampleBuffer = try await videoTrackOutputProvider.next() {
                    if let transformedBuffer = try transform(from: sampleBuffer, with: pixelBufferPool, in: transferSession) {
                        videoRenderer.enqueue(transformedBuffer)
                    }
                }

                // Indicate that processing is substantially complete.
                isProcessing = false
            }

            // Conclude processing.
            assetReader.cancelReading()
            VTPixelTransferSessionInvalidate(transferSession)
        }
    }

    // MARK: Private behavior

    /// Transforms a frame-packed input sample into stereo output.
    /// - Parameters:
    ///   - sourceSampleBuffer: The input sample buffer to be processed.
    ///   - pixelBufferPool: The pixel buffer pool.
    ///   - transferSession: The pixel transfer session.
    /// - Returns: The output sample buffer to be rendered.
    private func transform(
        from sourceSampleBuffer: CMReadySampleBuffer<CMSampleBuffer.DynamicContent>,
        with pixelBufferPool: CVMutablePixelBuffer.Pool,
        in transferSession: VTPixelTransferSession
    ) throws -> CMSampleBuffer? {
        var transformedBuffer: CMSampleBuffer? = nil

        try sourceSampleBuffer.withUnsafeSampleBuffer { cmSampleBuffer in
            guard let sourceImageBuffer = CMSampleBufferGetImageBuffer(cmSampleBuffer) else {
                fatalError("Failed to load source samples as an image buffer")
            }

            let layerIDs = [0, 1]
            let eyeComponents: [CMStereoViewComponents] = [.leftEye, .rightEye]
            var taggedBuffers = [CMTaggedDynamicBuffer]()
            for (layerID, eye) in zip(layerIDs, eyeComponents) {
                let pixelBuffer = try pixelBufferPool.makeMutablePixelBuffer()

                // Crop the transfer region to the current eye.
                let bufferSize = pixelBufferPool.pixelBufferAttributes.size
                let apertureOffset = stereoMetadata.apertureOffset(for: bufferSize, layerID: layerID)
                let cropRectDict = [
                    kCVImageBufferCleanApertureHorizontalOffsetKey: apertureOffset.horizontal,
                    kCVImageBufferCleanApertureVerticalOffsetKey: apertureOffset.vertical,
                    kCVImageBufferCleanApertureWidthKey: bufferSize.width,
                    kCVImageBufferCleanApertureHeightKey: bufferSize.height
                ]
                CVBufferSetAttachment(sourceImageBuffer, kCVImageBufferCleanApertureKey, cropRectDict as CFDictionary, .shouldPropagate)
                VTSessionSetProperty(transferSession, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_CropSourceToCleanAperture)

                // Transfer the image to the pixel buffer.
                pixelBuffer.withUnsafeBuffer { cvPixelBuffer in
                    let transferResult = VTPixelTransferSessionTransferImage(transferSession, from: sourceImageBuffer, to: cvPixelBuffer)
                    guard transferResult == kCVReturnSuccess else {
                        fatalError("Error during pixel transfer session for layer \(layerID): \(transferResult)")
                    }
                }

                // Create and append a tagged buffer for this eye.
                let tags: [CMTag] = [.videoLayerID(Int64(layerID)), .stereoView(eye), .mediaType(.video)]
                taggedBuffers.append(CMTaggedDynamicBuffer(tags: tags, content: .pixelBuffer(CVReadOnlyPixelBuffer(pixelBuffer))))
            }

            let buffer = CMReadySampleBuffer(
                taggedBuffers: taggedBuffers,
                formatDescription: CMTaggedBufferGroupFormatDescription(taggedBuffers: taggedBuffers),
                presentationTimeStamp: cmSampleBuffer.presentationTimeStamp,
                duration: cmSampleBuffer.duration
            )
            buffer.withUnsafeSampleBuffer { buffer in
                transformedBuffer = buffer
            }
        }

        return transformedBuffer
    }
    
    /// Asynchronously prepare the video renderer to receive sample buffers.
    private func untilReadyForMoreMediaData() async {
        let continuationCountMutex = Mutex(0)
        await withCheckedContinuation { continuation in
            videoRenderer.requestMediaDataWhenReady(on: .global()) {
                let count = continuationCountMutex.withLock { count in
                    count += 1
                    return count
                }
                guard count <= 1 else { return }
                continuation.resume()
            }
        }
    }
}
