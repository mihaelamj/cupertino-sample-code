/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Writes AIVU files from provided inputs using the `AVAssetWriter` class in AVFoundation.
*/

import Foundation
import AVFoundation
import ImmersiveMediaSupport

class CreateAIVUWriter {
    /// Create an AIVU file with the provided input video, the `ImmersiveMediaSupport` `VenueDescriptor` and `PresentationDescriptor`,
    /// and output to the provided output URL.
    /// - Parameters:
    ///   - video: Input URL for the MV-HEVC MOV to be converted into AIVU.
    ///   - venue: `VenueDescriptor` to included within the AIVU file for the input video's camera calibrations.
    ///   - presentation: `PresentationDescriptor` to be written as timed metadata to the output AIVU file.
    ///   - outputURL: The location to write the AIVU file to.
    static func create(from video: URL, venue: VenueDescriptor, presentation: PresentationDescriptor, to outputURL: URL) async throws {
        try await withThrowingTaskGroup { group in
            // Setup the asset reader.
            let asset = AVURLAsset(url: video)
            let assetReader = try AVAssetReader(asset: asset)
            
            // Get the video and audio track providers.
            let videoTrackProvider = try await getOutputProvider(from: asset, mediaType: .video, assetReader: assetReader)
            let audioTrackProvider = try? await getOutputProvider(from: asset, mediaType: .audio, assetReader: assetReader)
            
            try assetReader.start()
            
            // Setup the asset writer.
            let assetWriter = try AVAssetWriter(url: outputURL, fileType: .mov)
            assetWriter.movieTimeScale = CMTimeScale(90_000) // Set a default timescale of 90 fps for AIV.
            
            // Setup video input receiver.
            let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: nil)
            videoInput.mediaTimeScale = CMTimeScale(90_000) // Set a default timescale of 90 fps for AIV.
            videoInput.marksOutputTrackAsEnabled = true
            videoInput.transform = .identity
            let videoInputReceiver = assetWriter.inputReceiver(for: videoInput)
            
            // Setup audio input receiver.
            let audioInput = (audioTrackProvider != nil) ? AVAssetWriterInput(mediaType: .audio, outputSettings: nil) : nil
            let audioInputReceiver = (audioTrackProvider != nil) ? assetWriter.inputReceiver(for: audioInput!) : nil
            
            // Setup metadata input receiver.
            let metadataInput = AVAssetWriterInput(mediaType: .metadata, outputSettings: nil, sourceFormatHint: try getMetadataFormatDescription())
            let metadataInputReceiver = assetWriter.inputMetadataReceiver(for: metadataInput)
            
            // Add the `VenueDescriptor` metadata item to the `AVAssetWriter`.
            if let aimeMetadataItems = await getMetadataItem(from: venue) {
                assetWriter.metadata.append(aimeMetadataItems)
            }
            
            try assetWriter.start()
            assetWriter.startSession(atSourceTime: .zero)
            
            group.addTask {
                // Create a `PresentationDescriptorReader` from the `PresentationDescriptor` to read commands from a specific timestamp.
                let dynamicMetadataReader = PresentationDescriptorReader(presentationDescriptor: presentation)
                var timedMetadataGroups: [AVTimedMetadataGroup] = []
                
                // Read every video frame from the output and write it to the input,
                // while also getting the metadata information for that frame.
                while let buffer = try await videoTrackProvider.next() {
                    if let timedMetadataGroup = getTimedMetadataGroup(buffer: buffer, reader: dynamicMetadataReader),
                       !timedMetadataGroups.contains(where: { $0.timeRange.start == buffer.presentationTimeStamp }) {
                        timedMetadataGroups.append(timedMetadataGroup)
                    }
                    
                    // Append the frame buffer to the input receiver.
                    try await videoInputReceiver.append(buffer)
                }
                videoInputReceiver.finish()
                
                timedMetadataGroups.sort(by: { $0.timeRange.start < $1.timeRange.start })
                
                // Add each timed metadata group to the receiver.
                for metadataGroup in timedMetadataGroups {
                    try await metadataInputReceiver.append(metadataGroup)
                }
                metadataInputReceiver.finish()
            }
            
            group.addTask {
                // Read every audio buffer from the output and write it to the input.
                while let audioBuffer = try await audioTrackProvider?.next() {
                    try await audioInputReceiver?.append(audioBuffer)
                }
                audioInputReceiver?.finish()
            }
            
            try await group.waitForAll()
            await assetWriter.finishWriting()
        }
    }
    
    /// Converts the `VenueDescriptor` into an `AVMetadataItem` so it can be written into the AIVU file.
    /// - Parameter venue: `VenueDescriptor` to be converted into an `AVMetadataItem`.
    /// - Returns: `AVMetadataItem` from the provided `VenueDescriptor`.
    private static func getMetadataItem(from venue: VenueDescriptor) async -> AVMetadataItem? {
        // Get the AIME data from the provided `VenueDescriptor`.
        if let aimeData = try? await venue.aimeData {
            let aimeMetadataItem = AVMutableMetadataItem()
            // Set the identifier of the `AVMetadataItem` to the AIME data identifier.
            aimeMetadataItem.identifier = AVMetadataIdentifier.quickTimeMetadataAIMEData
            aimeMetadataItem.dataType = String(kCMMetadataBaseDataType_RawData)
            // Set the value as the AIME data.
            aimeMetadataItem.value = aimeData as NSData
            
            return aimeMetadataItem
        }
        return nil
    }
    
    /// Creates the timed `AVMetadataItem` from the provided `PresentationDescriptorReader` with the provided time and duration of the frame buffer.
    /// - Parameters:
    ///   - presentationReader: Reader to provide the commands for a specific timestamp of a `PresentationDescriptor`.
    ///   - time: Time to request for the presentation commands for.
    ///   - frameDuration: Duration of the frame buffer to write metadata to.
    /// - Returns: Timed `AVMetadataItem` of the `PresentationDescriptor` commands for the given time and frame duration.
    private static func getMetadataItem(from presentationReader: PresentationDescriptorReader,
                                        for time: CMTime,
                                        frameDuration: CMTime) throws -> AVMetadataItem? {
        // Get the commands for the given time from the `PresentationDescriptorReader`.
        let presentationCommands = presentationReader.outputPresentationCommands(for: time) ?? []
        if presentationCommands.isEmpty { return nil }
        
        // Encode the commands.
        let encodedData = try JSONEncoder().encode(presentationCommands)
        
        let presentationMetadataItem = AVMutableMetadataItem()
        // Set the identifier of the `AVMetadataItem` for the presentation data.
        presentationMetadataItem.identifier = AVMetadataIdentifier.quickTimeMetadataPresentationImmersiveMedia
        presentationMetadataItem.dataType = String(kCMMetadataBaseDataType_RawData)
        // Set the value of the encoded commands for the provided time.
        presentationMetadataItem.value = encodedData as NSData
        presentationMetadataItem.time = time
        presentationMetadataItem.duration = frameDuration
        
        return presentationMetadataItem
    }
    
    /// Given an frame buffer and `PresentationDescriptorReader`, this provides the timed metadata group for that specific frame buffer.
    /// - Parameters:
    ///   - buffer: Frame buffer to get the metadata for.
    ///   - reader: Reader to provide the commands for a specific timestamp of a `PresentationDescriptor`.
    /// - Returns: `AVTimedMetadataGroup` for the timed metadata of the given frame buffer.
    private static func getTimedMetadataGroup(buffer: CMReadySampleBuffer<CMSampleBuffer.DynamicContent>,
                                              reader: PresentationDescriptorReader) -> AVTimedMetadataGroup? {
        let outputTimeStamp = buffer.presentationTimeStamp
        let outputDuration = buffer.duration
        
        // Get the metadata for the frame buffer.
        if let metadata = try? getMetadataItem(from: reader, for: outputTimeStamp, frameDuration: outputDuration) {
            let metadataTimeRange = CMTimeRange(start: outputTimeStamp, end: outputTimeStamp + outputDuration)
            let timedMetadataGroup = AVTimedMetadataGroup(items: [metadata], timeRange: metadataTimeRange)
            return timedMetadataGroup
        }
        return nil
    }
    
    /// Gets the output provider for the given asset's media type track and asset reader.
    /// - Parameters:
    ///   - asset: Asset used to create the reader with the desired media track.
    ///   - mediaType: The desired media type for the track from the asset.
    ///   - assetReader: The `AVAssetReader` for the output provider.
    /// - Returns: The output provider for the `AVAssetReader`.
    private static func getOutputProvider(from asset: AVAsset,
                                          mediaType: AVMediaType,
                                          assetReader: AVAssetReader)
    async throws -> sending AVAssetReaderOutput.Provider<CMReadySampleBuffer<CMSampleBuffer.DynamicContent>> {
        guard let assetTrack = try await asset.loadTracks(withMediaType: mediaType).first else {
            throw RuntimeError("Could not find \(mediaType.rawValue) track")
        }
        let readerOutput = AVAssetReaderTrackOutput(track: assetTrack, outputSettings: nil)
        return assetReader.outputProvider(for: readerOutput)
    }
    
    /// Create the `CMFormatDescription` for the timed metadata track.
    /// - Returns: The `CMFormatDescription` of the timed metadata source format hint.
    private static func getMetadataFormatDescription() throws -> CMFormatDescription {
        let specification = [
            kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier: kCMMetadataIdentifier_QuickTimeMetadataPresentationImmersiveMedia,
            kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType: kCMMetadataBaseDataType_RawData
        ] as [String: CFPropertyList]
        
        return try CMFormatDescription(boxedMetadataSpecifications: [specification])
    }
}
