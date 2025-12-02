/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Supported actions of Spatial Audio command-line interface.
*/

@preconcurrency import Cinematic

struct Actions {
    @MainActor
    /*
     Use `AVPlayer` with an `AVAudioMix` to preview the audio mix parameters for
     a number of seconds that the 'duration' option specifies.
     */
    static func preview(_ previewInput: SpatialUtility.PreviewInput) async throws {
        
        print("Preview: effectIntensity=\(previewInput.intensity), renderingStyle=\(previewInput.style)")
        
        let asset = AVURLAsset(url: previewInput.inputFile)
        
        let audioInfo = try await CNAssetSpatialAudioInfo(asset: asset)
        
        // Verify the style input.
        guard let renderingStyle = SpatialUtility.renderingStylesMap[previewInput.style] else {
            throw SpatialUtility.RuntimeError("style input is not a valid rendering style")
        }
        
        // Return an `AVAudioMix` with effect intensity and rendering style.
        let newAudioMix = audioInfo.audioMix(effectIntensity: previewInput.intensity,
                                             renderingStyle: renderingStyle)
        
        // Set the new `AVAudioMix` on an `AVPlayerItem`.
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.audioMix = newAudioMix
        let player = AVPlayer(playerItem: playerItem)
        
        // Play the input file for <duration>.
        player.play()
        try await Task.sleep(nanoseconds: UInt64(previewInput.duration * 1e9))
    }
    
    /*
     Use `AVAssetReader` and `AVAssetWriter` to apply the specified audio mix
     parameters to the input, and save the result to the specified output file.
     Include a stereo compatibility track.
     */
    static func bake(_ bakeInput: SpatialUtility.BakeInput) async throws {
        
        // Array of source reader outputs and destination writer inputs.
        var bakeTracks : [(source: AVAssetReaderOutput, destination: AVAssetWriterInput)] = []
        
        let asset = AVURLAsset(url: bakeInput.inputFile)
        
        let audioInfo = try await CNAssetSpatialAudioInfo(asset: asset)
        
        // Verify the style input.
        guard let renderingStyle = SpatialUtility.renderingStylesMap[bakeInput.style] else {
            throw SpatialUtility.RuntimeError("style input is not a valid rendering style") }
        
        // Return an `AVAudioMix` with effect intensity and rendering style.
        let newAudioMix = audioInfo.audioMix(effectIntensity: bakeInput.intensity, renderingStyle: renderingStyle)
        
        let assetReader = try AVAssetReader(asset: asset)
        let assetWriter = try AVAssetWriter(outputURL: bakeInput.outputFile, fileType: .mov)
        
        // Apply the Audio Mix parameters to the stereo reader output.
        let readerOutputStereo = AVAssetReaderAudioMixOutput(
            audioTracks: [audioInfo.defaultSpatialAudioTrack],
            audioSettings: audioInfo.assetReaderOutputSettings(for: .stereo))
        readerOutputStereo.audioMix = newAudioMix
        
        // Create stereo writer input.
        let writerInputStereo = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: audioInfo.assetWriterInputSettings(for: .stereo))
        
        // Apply the Audio Mix parameters to the spatial reader output.
        let readerOutputSpatial = AVAssetReaderAudioMixOutput(
            audioTracks: [audioInfo.defaultSpatialAudioTrack],
            audioSettings: audioInfo.assetReaderOutputSettings(for: .spatial))
        readerOutputSpatial.audioMix = newAudioMix
        
        // Create spatial writer input. Mark track as disabled.
        let writerInputSpatial = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: audioInfo.assetWriterInputSettings(for: .spatial))
        writerInputSpatial.marksOutputTrackAsEnabled = false
        
        // Add fallback track association between stereo and spatial tracks.
        writerInputSpatial.addTrackAssociation(
            withTrackOf: writerInputStereo,
            type: AVAssetTrack.AssociationType.audioFallback.rawValue)
        
        assetWriter.add(.init(inputs: [writerInputStereo, writerInputSpatial], defaultInput: writerInputStereo))
        
        // Add the respective reader outputs and writer inputs to the
        // source/destination array.
        bakeTracks.append((source: readerOutputStereo, destination: writerInputStereo))
        bakeTracks.append((source: readerOutputSpatial, destination: writerInputSpatial))
        
        if bakeInput.includeVideo {
            for track in try await asset.loadTracks(withMediaType: .video) {
                let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: nil)
                writerInput.transform = try await track.load(.preferredTransform)
                bakeTracks.append((
                    source:  AVAssetReaderTrackOutput(track: track, outputSettings: nil),
                    destination: writerInput))
            }
        }
        
        // Add each source and destination to the main asset reader and writer.
        bakeTracks.forEach { bakeTrack in
            assetReader.add(bakeTrack.source)
            assetWriter.add(bakeTrack.destination)
        }
        
        // Perform the reading and writing.
        await bakeReadWrite(assetReader, assetWriter, bakeTracks)
    }
    
    // Function that performs the AVAsset reading and writing with Bake.
    static func bakeReadWrite(_ assetReader: AVAssetReader, _ assetWriter: AVAssetWriter,
                              _ bakeTracks: [(source: AVAssetReaderOutput, destination: AVAssetWriterInput)]) async {
        
        let queue = DispatchQueue(label: "SpatialAudioCLI")
        
        // Start reading & writing session on queue
        assetReader.startReading()
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
        
        await withTaskGroup(of: Void.self) { taskGroup in
            bakeTracks.forEach { bakeTrack in
                let source = bakeTrack.source
                let destination = bakeTrack.destination
                taskGroup.addTask {
                    await withCheckedContinuation { check in
                        destination.requestMediaDataWhenReady(on: queue) {
                            var isProcessing = true
                            while isProcessing && destination.isReadyForMoreMediaData {
                                if let sampBuf = source.copyNextSampleBuffer() {
                                    destination.append(sampBuf)
                                } else {
                                    isProcessing.toggle()
                                    destination.markAsFinished()
                                    check.resume()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        await assetWriter.finishWriting()
        print("done")
    }
    
    /*
     Use `AUAudioMix` to apply the specified audio mix parameters to the input,
     and save the result to the specified output file, rendered to the channel
     layout that the "audio output format" option specifies.
     */
    static func process(_ processInput: SpatialUtility.ProcessInput) async throws {
        
        // Initialize the class that hosts `AUAudioMix`.
        let audioUnitHost = AudioUnitHost()
        
        // Verify the style input.
        guard let renderingStyle = SpatialUtility.renderingStylesMap[processInput.style] else {
            throw SpatialUtility.RuntimeError("style input is not a valid rendering style") }
        
        let asset = AVURLAsset(url: processInput.inputFile)
        
        let audioInfo = try await CNAssetSpatialAudioInfo(asset: asset)
        
        // Read metadata from the asset.
        let remixMetadata = audioInfo.spatialAudioMixMetadata as CFData
        
        // Read properties of the Spatial Audio track.
        let spatialTrack = audioInfo.defaultSpatialAudioTrack
        let spatialTrackFormat = try await spatialTrack.load(.formatDescriptions).first
        let inASBD = CMAudioFormatDescriptionGetStreamBasicDescription(spatialTrackFormat!)
        let sampleRate = inASBD!.pointee.mSampleRate
        let numChannelsIn = inASBD!.pointee.mChannelsPerFrame
        let numChannelsOut = SpatialUtility.outputChannelMap[processInput.audioOutputFormat]!
        
        // Input audio stream basic description.
        let kInputASBD = AudioStreamBasicDescription(
            mSampleRate: sampleRate, mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kLinearPCMFormatFlagIsFloat | kLinearPCMFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved,
            mBytesPerPacket: 4, mFramesPerPacket: 1, mBytesPerFrame: 4,
            mChannelsPerFrame: numChannelsIn, mBitsPerChannel: 32, mReserved: 0)
        
        // Output audio stream basic description.
        var kOutputASBD = AudioStreamBasicDescription(
            mSampleRate: sampleRate, mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kLinearPCMFormatFlagIsFloat | kLinearPCMFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved,
            mBytesPerPacket: 4, mFramesPerPacket: 1, mBytesPerFrame: 4,
            mChannelsPerFrame: numChannelsOut, mBitsPerChannel: 32, mReserved: 0)
        
        // Set properties and parameters on `AUAudioMix` and initialize.
        let setupInput = SpatialUtility.SetupAudioMixInput(inputASBD: kInputASBD,
                                                           outputASBD: kOutputASBD,
                                                           metadata: remixMetadata,
                                                           intensity: processInput.intensity,
                                                           style: renderingStyle
        )
        audioUnitHost.setupAUAudioMix(setupInput)
        
        // Create .tmp file for extracting the FOA track from input file.
        let tmpDir = FileManager().temporaryDirectory
        let tmpAudioURL = tmpDir.appendingPathComponent("foa").appendingPathExtension("caf")
        
        // Create .tmp URL for the processed output.
        let tmpAudioProcessURL = tmpDir.appendingPathComponent("processed").appendingPathExtension("caf")
        
        SpatialUtility.deleteFiles([tmpAudioURL, tmpAudioProcessURL])
        
        // Extract the input FOA track to the .tmp file.
        try await exportFOAtoFile(spatialTrack, tmpAudioURL)
        
        // Create output format using specified output channel layout
        let outputFormat = AVAudioFormat(
            streamDescription: &kOutputASBD,
            channelLayout: SpatialUtility.outputLayoutMap[processInput.audioOutputFormat] as? AVAudioChannelLayout)
        
        // Process the input with `AUAudioMix`.
        try await audioUnitHost.processWithAUAudioMix(tmpAudioURL, outputFormat!, tmpAudioProcessURL)
        
        // Export the processed audio to the output file.
        try await saveProcessedFile(tmpAudioProcessURL, asset, processInput.includeVideo, processInput.outputFile)
        
        SpatialUtility.deleteFiles([tmpAudioProcessURL, tmpAudioURL])
    }
    
    // Extract the input FOA track to the .tmp file.
    static func exportFOAtoFile(_ spatialTrack: AVAssetTrack, _ tmpAudioURL: URL) async throws {
        // Extract the input FOA track to the tmp file.
        let composition = AVMutableComposition()
        let audioTimeRange = try await spatialTrack.load(.timeRange)
        guard let audioCompositionTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: CMPersistentTrackID(truncating: 1)) else {
            throw SpatialUtility.RuntimeError("could not add input FOA track to new composition")
        }
        
        try audioCompositionTrack.insertTimeRange(audioTimeRange, of: spatialTrack, at: .zero)
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
            throw SpatialUtility.RuntimeError("could not create export session for input FOA composition")
        }
        exportSession.outputFileType = .caf
        exportSession.outputURL = tmpAudioURL
        try await exportSession.export(to: tmpAudioURL, as: .caf)
    }
    
    // Export the processed audio to the output file.
    static func saveProcessedFile(_ tmpAudioProcessURL: URL, _ asset: AVAsset, _ includeVideo: Bool, _ outputFile: URL) async throws {
        
        let composition = AVMutableComposition()
        let processedAudioAsset = AVURLAsset(url: tmpAudioProcessURL)
        let processedAudioTrack = try await processedAudioAsset.loadTracks(withMediaType: .audio).first
        let processedAudioTimeRange = try await processedAudioTrack!.load(.timeRange)
        
        guard let audioCompositionTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: CMPersistentTrackID(truncating: 1)) else {
            throw SpatialUtility.RuntimeError("could not add processed audio track to new composition")
        }
        
        try audioCompositionTrack.insertTimeRange(processedAudioTimeRange, of: processedAudioTrack!, at: .zero)
        
        if includeVideo {
            
            let videoTrack = try await asset.loadTracks(withMediaType: .video).first
            let videoTimeRange = try await videoTrack!.load(.timeRange)
            
            guard let videoCompositionTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: CMPersistentTrackID(truncating: 2)) else {
                throw SpatialUtility.RuntimeError("could not add video track to processed composition")
            }
            try videoCompositionTrack.insertTimeRange(videoTimeRange, of: videoTrack!, at: .zero)
            videoCompositionTrack.preferredTransform = try await videoTrack!.load(.preferredTransform)
            
            // Export the movie composition to a .mov file.
            guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
                throw SpatialUtility.RuntimeError("could not create export session for processed movie")
            }
            exportSession.outputURL = outputFile
            exportSession.outputFileType = .mov
            print("saving processed movie file...")
            try await exportSession.export(to: outputFile, as: .mov)
            
        } else {
            // Export the audio-only composition to a .caf file.
            guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
                throw SpatialUtility.RuntimeError("could not create export session for processed audio")
            }
            exportSession.outputURL = outputFile
            exportSession.outputFileType = .caf
            print("saving processed audio file...")
            try await exportSession.export(to: outputFile, as: .caf)
        }
    }
}
