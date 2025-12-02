/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that records Spatial Audio.
*/

import AVFoundation
import Combine
import CoreFoundation
import CoreMedia
import Foundation

@Observable
class AudioRecorder: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate, @unchecked Sendable {
    
    // The applications asset writer.
    private var assetWriter: AVAssetWriter?
    
    // The applications capture session.
    private var session: AVCaptureSession
    
    // The stereo audio data output for this session.
    private var stereoAudioDataOutput: AVCaptureAudioDataOutput?
    
    // The spatial audio data output for this session.
    private var spatialAudioDataOutput: AVCaptureAudioDataOutput?
    
    // The spatial audio metadata sample generator.
    private var spatialAudioMetaDataSampleGenerator: AVCaptureSpatialAudioMetadataSampleGenerator?
    
    // The audio device for the session.
    private var audioDevice: AVCaptureDevice?
    
    // The metadata asset writer input.
    private var assetWriterMetadataInput: AVAssetWriterInput?
    
    // The spatial audio asset writer input.
    private var assetWriterSpatialAudioInput: AVAssetWriterInput?
    
    // The stereo audio asset writer input.
    private var assetWriterStereoAudioInput: AVAssetWriterInput?
    
    // Communicate with the session and other session objects on this queue.
    private var sessionQueue: DispatchQueue
    
    // A Boolean value that indicates whether the app is recording for the delegate callback methods.
    private var isRecordForCallBacks = false
    
    // The URL of the recorded audio file.
    public var fileURL: URL?
    
    // A Boolean value that indicates whether the app is recording.
    var isRecording = false
    
    // The curent level of recorded audio for the waveform user interface.
    var currentLevel: Float = 0.0
    
    // An array of amplitude values.
    var amplitudes: [Float] = []
    
    override init() {
        
        // The applications capture session.
        session = AVCaptureSession()
        
        // Initialize the AVCaptureDevice for the capture session.
        if let audioCaptureDevice = AVCaptureDevice.default(for: .audio) {
            audioDevice = audioCaptureDevice
        }
        
        // Initialize the spatial audio data output for the capture session.
        spatialAudioDataOutput = AVCaptureAudioDataOutput()
        
        // Initialize the stereo audio data output for the capture session.
        stereoAudioDataOutput = AVCaptureAudioDataOutput()
        
        // Initialize the spatial audio metadata sample generator for the capture session.
        spatialAudioMetaDataSampleGenerator = AVCaptureSpatialAudioMetadataSampleGenerator()
        
        // Initialize the sessionQueue.
        sessionQueue = DispatchQueue(label: "sessionQueue")
        
        // Initialize the variables for waveform values.
        self.currentLevel = 0.0
        self.amplitudes = []
        
    }
    
    func setupCaptureSession() {
        
        if let spatialAudioDataOutput, let stereoAudioDataOutput {
            // Set spatial audio channel layout tag to High Order Ambisonics.
            spatialAudioDataOutput.spatialAudioChannelLayoutTag = ( kAudioChannelLayoutTag_HOA_ACN_SN3D | 4 )
            // Set stereo audio channel layout tag to standard stereo stream.
            stereoAudioDataOutput.spatialAudioChannelLayoutTag = kAudioChannelLayoutTag_Stereo
        }
        
        // Begin the session configuration for the capture session.
        session.beginConfiguration()
        
        do {
            if let audioDevice {
                
                // The audio device input for the capture session.
                let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
                
                // Add the audio device input to the capture session.
                if session.canAddInput(audioDeviceInput) {
                    session.addInput(audioDeviceInput)
                    
                    // Set the audio device input multichannel audio mode to first order ambisonics.
                    if audioDeviceInput.isMultichannelAudioModeSupported(.firstOrderAmbisonics) {
                        audioDeviceInput.multichannelAudioMode = .firstOrderAmbisonics
                    } else {
                        fatalError("Could not set the audio device input multichannel audio mode to first order ambisonics. Run this sample code on a device that supports Spatial Audio capture, such as an iPhone 16 Pro or later.")
                    }
                } else {
                    print("Could not add audio device input to the session.")
                }
            } else {
                print("Could not create the audio device.")
            }
        } catch {
            print("Could not create audio device input: \(error).")
        }
        
        if let stereoAudioDataOutput, let spatialAudioDataOutput {
            
            // Add spatial audio data output to the capture session.
            if session.canAddOutput(spatialAudioDataOutput) {
                session.addOutput(spatialAudioDataOutput)
            } else {
                print("Could not add spatial audio data output to the session")
            }
            
            // Add stereo audio data output to the capture session.
            if session.canAddOutput(stereoAudioDataOutput) {
                session.addOutput(stereoAudioDataOutput)
            } else {
                print("Could not add stereo audio data output to the session")
            }
        }
        
        // Commit the session configuration for the capture session.
        session.commitConfiguration()
        
        if let spatialAudioDataOutput, let stereoAudioDataOutput {
            // Set the sample buffer delegate for the spatial audio data output.
            spatialAudioDataOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            
            // Set the sample buffer delegate for the stereo audio data output.
            stereoAudioDataOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
        }
        
        sessionQueue.async {
            self.session.startRunning()
        }
    }
    
    // A utility function to create a URL for the recorded audio file.
    func generateURL() -> URL {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("The app failed to recieve a url to the document directory")
        }
        let randomFileName = UUID().uuidString + ".mov"
        let randomURL = documentsURL.appendingPathComponent(randomFileName)
        return randomURL
    }
    
    // A function to setup the asset writer with both spatial and stereo audio output.
    private func setupAssetWriterWithSpatialAndStereoAudioOutput(_ spatialAudioOutput: AVCaptureAudioDataOutput, _ stereoAudioOutput: AVCaptureAudioDataOutput) {
        
        // Create and assign the URL for the recorded audio file.
        let writableFileURL = generateURL()
        self.fileURL = writableFileURL
        
        guard let fileURL else {
            fatalError("Unable to obtain file URL.")
        }
        
        do {
            // Create the avassetwriter object.
            self.assetWriter = try AVAssetWriter(url: fileURL, fileType: .mov)
            
        } catch {
            print("Could not create AVAssetWriter: \(error).")
        }
        
        // Assigning audio settings for spatial audio output.
        let assetWriterSpatialAudioSettings = spatialAudioOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mov)
        
        // Assigning asset writer input for spatial audio.
        self.assetWriterSpatialAudioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: assetWriterSpatialAudioSettings)
        self.assetWriterSpatialAudioInput?.expectsMediaDataInRealTime = true
        
        // Adding spatial audio input to the asset writer.
        if let assetWriter, let assetWriterSpatialAudioInput, assetWriter.canAdd(assetWriterSpatialAudioInput) {
            assetWriter.add(assetWriterSpatialAudioInput)
        }
        
        // Assigning audio settings for stereo audio output.
        let assetWriterStereoAudioSettings = stereoAudioOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mov)
        
        // Assigning asset writer input for stereo audio.
        self.assetWriterStereoAudioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: assetWriterStereoAudioSettings)
        self.assetWriterStereoAudioInput?.expectsMediaDataInRealTime = true
        
        // Adding stereo audio input to the asset writer.
        if let assetWriter, let assetWriterStereoAudioInput, assetWriter.canAdd(assetWriterStereoAudioInput) {
            assetWriter.add(assetWriterStereoAudioInput)
        }
        
        // Assigning format description for spatial audio metadata sample generator output.
        let spatialAudioMetadataFormatDescription = self.spatialAudioMetaDataSampleGenerator!.timedMetadataSampleBufferFormatDescription
        
        // Assigning asset writer input for metadata input.
        self.assetWriterMetadataInput = AVAssetWriterInput(mediaType: .metadata, outputSettings: nil, sourceFormatHint: spatialAudioMetadataFormatDescription)
        self.assetWriterMetadataInput?.expectsMediaDataInRealTime = true
        
        // Adding spatial metadata input to the asset writer.
        if let assetWriter, let assetWriterMetadataInput, assetWriter.canAdd(assetWriterMetadataInput) {
            assetWriter.add(assetWriterMetadataInput)
            
            if let assetWriterSpatialAudioInput, assetWriterMetadataInput.canAddTrackAssociation(withTrackOf: assetWriterSpatialAudioInput, type: AVAssetTrack.AssociationType.metadataReferent.rawValue) {
                // Adding track association of the spatial audio input to the metadata input.
                assetWriterMetadataInput.addTrackAssociation(withTrackOf: assetWriterSpatialAudioInput, type: AVAssetTrack.AssociationType.metadataReferent.rawValue)
            }
        }
        
        // Add the stereo or spatial track's fallback relationship and mark them as enabled/disabled
        if let assetWriterSpatialAudioInput, let assetWriterStereoAudioInput {
            assetWriterStereoAudioInput.canAddTrackAssociation(withTrackOf: assetWriterSpatialAudioInput, type: AVAssetTrack.AssociationType.audioFallback.rawValue)

            // Mark output tracks as enabled true and then false for stereo audio input.
            assetWriterStereoAudioInput.marksOutputTrackAsEnabled = true
            assetWriterStereoAudioInput.marksOutputTrackAsEnabled = false
            
            // Assign all audio tracks in the same alternate group ID and set the language/extended tags as undefined also known as "und".
            assetWriterSpatialAudioInput.languageCode = "und"
            assetWriterSpatialAudioInput.extendedLanguageTag = "und"
        
        }
        
    }
    
    // Function to set the variables for the audio record class when recording starts.
    func startRecording() {
        sessionQueue.async { [self] in
            isRecordForCallBacks = true
            DispatchQueue.main.async {
                self.isRecording = true
            }
        }
    }
    
    // Function to set the variables for the audio record class when recording stops.
    func stopRecording() async {
        sessionQueue.async { [self] in
            self.isRecordForCallBacks = false
            DispatchQueue.main.async {
                self.isRecording = false
            }
        }
    }
    
    // The delegate callback method for the didDrop sample buffer.
    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Dropped Sample Buffer: \(sampleBuffer) from  Connection: \(connection) and  output: \(captureOutput)")
    }
    
    // The delegate callback method for the didOutput sample buffer.
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // If the app isn't recording, finish writing for the avassetwriter and then assign to `nil`.
        if !isRecordForCallBacks {
            if self.assetWriter != nil {
                self.appendSpatialAudioMetadataSample()
                self.assetWriter?.finishWriting(completionHandler: {})
                self.assetWriter = nil
            }
            return
        }
        
        // If the app hasn't started a session for asset writer, start the session now.
        if self.assetWriter == nil {
            if let spatialOutput = spatialAudioDataOutput, let stereoOutput = stereoAudioDataOutput {
                
                // Setup the asset writer with both spatial and stereo audio output.
                self.setupAssetWriterWithSpatialAndStereoAudioOutput(spatialOutput, stereoOutput)
                
                // Start writing for the asset writer.
                self.assetWriter?.startWriting()
                
                // Start the session for the asset writer.
                self.assetWriter?.startSession(atSourceTime: sampleBuffer.presentationTimeStamp)
            }
        }

        // The media type of the format description from the CMSampleBuffer object.
        if let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer), let spatialInput = assetWriterSpatialAudioInput, let stereoInput = assetWriterStereoAudioInput {
            let mediaType = CMFormatDescriptionGetMediaType(formatDescription)
            
            if mediaType == kCMMediaType_Audio {
                if spatialInput.isReadyForMoreMediaData {
                    if output == self.spatialAudioDataOutput {
                        // Append the sample buffer to the spatial audio input.
                        self.appendSampleBufferForSpatialAudio(sampleBuffer)
                    }
                }
                
                if stereoInput.isReadyForMoreMediaData {
                    if output == self.stereoAudioDataOutput {
                        // Append the sample buffer to the stereo audio input.
                        stereoInput.append(sampleBuffer)
                        // Create values for the recording wave form UI form the sample buffer.
                        computeValuesForWaveFormUI(sampleBuffer)
                    }
                }
            }
        }
        
    }
    
    // Function to compute amplitude values from audio samples for use in a waveform UI visualization.
    func computeValuesForWaveFormUI(_ sampleBuffer: CMSampleBuffer) {
            
        // Get the block buffer containing audio data.
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }

        // Determine the size of the buffer and prepare an array to hold Float audio samples.
        let length = CMBlockBufferGetDataLength(blockBuffer)
        var floatData = [Float](repeating: 0, count: length / MemoryLayout<Float>.size)

        // Copy the raw audio data into the float array.
        let status = CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: &floatData)
        guard status == noErr else { return }

        // Calculate the Root Mean Square (RMS) value of the audio signal.
        // RMS provides a measure of the audio amplitude.
        let rms = sqrt(floatData.map { $0 * $0 }.reduce(0, +) / Float(floatData.count))
        
        // Clamp the RMS value to a maximum of 1.0 to normalize it.
        let normalized = min(rms, 1.0)

        // Update the UI on the main thread by appending the value to the amplitudes array.
        DispatchQueue.main.async {
            self.amplitudes.append(normalized)
            // Keep the array size to a maximum of 100 samples for display.
            if self.amplitudes.count > 100 {
                self.amplitudes.removeFirst()
            }
        }
    }
    
    // Function to append spatial audio metadata sample to the asset writer input.
    func appendSpatialAudioMetadataSample() {
        if let spatialAudioMetadataSample = self.spatialAudioMetaDataSampleGenerator?.newTimedMetadataSampleBufferAndResetAnalyzer(), let assetWriterMetadataInput {
            assetWriterMetadataInput.append(spatialAudioMetadataSample.takeRetainedValue())
        } else {
            fatalError("Was not able to get final sample buffer.")
        }
    }
    
    // Function to append the analyzed spatial audio sample buffer to asset writer input.
    func appendSampleBufferForSpatialAudio(_ sampleBuffer: CMSampleBuffer) {
        if !isRecordForCallBacks { return }
        var sampleBufferToWrite: CMSampleBuffer?
        if self.spatialAudioMetaDataSampleGenerator != nil {
            self.spatialAudioMetaDataSampleGenerator?.analyzeAudioSample(sampleBuffer)
            sampleBufferToWrite = createAudioSampleBufferCopy( sampleBuffer )
        } else {
            sampleBufferToWrite = createSpatialAudioSampleBufferCopy( sampleBufferToWrite! )
        }
        
        if self.isRecordForCallBacks {
            if let sampleBuffer = sampleBufferToWrite {
                self.assetWriterSpatialAudioInput?.append(sampleBuffer)
            }
        }
    }
    
    // A function that attempts to create a copy of a given CMSampleBuffer, fatally crashing if the copy operation fails.
    func createSpatialAudioSampleBufferCopy(_ sampleBuffer: CMSampleBuffer) -> CMSampleBuffer {
        var sampleBufferCopy: CMSampleBuffer? = nil

       let status = CMSampleBufferCreateCopy(
           allocator: kCFAllocatorDefault,
           sampleBuffer: sampleBuffer,
           sampleBufferOut: &sampleBufferCopy
       )

       if status == noErr {
           return sampleBufferCopy! // Returns the CMSampleBuffer
       } else {
           fatalError("Error: CMSampleBufferCreateCopy returned error \(status)")
       }
    }
    
    // A function that creates a deep copy of a CMSampleBuffer that contains audio data.
    func createAudioSampleBufferCopy(_ sampleBuffer: CMSampleBuffer) -> CMSampleBuffer {
        
        // Declare variables for the new buffer and metadata.
        var sampleBufferCopy: CMSampleBuffer?
        var blockBufferCopy: CMBlockBuffer?
        var sampleTimingArray: UnsafeMutableRawPointer?
        var sampleSize: UnsafeMutablePointer<Int>?
        
        // Get the data buffer from the original sample buffer.
        let dataBuffer = CMSampleBufferGetDataBuffer( sampleBuffer )
        
        if let dataBuffer {
            let dataLength = CMBlockBufferGetDataLength( dataBuffer )
            if dataLength > 0 {
                
                // If the data buffer exists and has data, get the data length and create a contiguous deep copy of the original data buffer (CMBlockBuffer).
                var err = CMBlockBufferCreateContiguous( allocator: kCFAllocatorDefault, sourceBuffer: dataBuffer, blockAllocator: kCFAllocatorDefault, customBlockSource: nil, offsetToData: 0, dataLength: dataLength, flags: kCMBlockBufferAlwaysCopyDataFlag, blockBufferOut: &blockBufferCopy )
                
                // Extract audio format description and number of samples.
                let formatDescription = CMSampleBufferGetFormatDescription( sampleBuffer )
                let numSamples = CMSampleBufferGetNumSamples( sampleBuffer )
                var numSampleTimeEntries: CMItemCount = 0
                
                // Copy sample timing information.
                // First get the count needed.
                // Allocate memory for the timing array.
                // Fill the timing array with actual timing data from the original buffer.
                err = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: 0, arrayToFill: nil, entriesNeededOut: &(numSampleTimeEntries))
                sampleTimingArray = malloc(numSampleTimeEntries * MemoryLayout<CMSampleTimingInfo>.size)
                let safeSampleTimingArray = sampleTimingArray
                let timingArrayPointer = unsafeBitCast(safeSampleTimingArray, to: UnsafeMutablePointer<CMSampleTimingInfo>.self)
                
                // Fill sampleSize with the size in bytes of each sample contained in sample buffer.
                err = CMSampleBufferGetSampleTimingInfoArray( sampleBuffer, entryCount: numSampleTimeEntries, arrayToFill: timingArrayPointer, entriesNeededOut: nil )
                
                // Assertion to ensure the function succeeded.
                assert(err == noErr, "CMSampleBufferGetSampleTimingInfoArray failed \(err)")
                
                // Copy sample size information --- same as above: determine count, allocate memory, then fill.
                var sampleSizeEntries: CMItemCount = 0
                err = CMSampleBufferGetSampleSizeArray( sampleBuffer, entryCount: 0, arrayToFill: nil, entriesNeededOut: &sampleSizeEntries)
                sampleSize = UnsafeMutablePointer<size_t>.allocate(capacity: sampleSizeEntries)
                
                // Fill sampleSize with the sizes of individual samples in the given sampleBuffer.
                err = CMSampleBufferGetSampleSizeArray( sampleBuffer, entryCount: sampleSizeEntries, arrayToFill: sampleSize, entriesNeededOut: nil )
                
                // Assertion to ensure the function succeeded.
                assert(err == noErr, "CMSampleBufferGetSampleSizeArray failed \(err)")
                
                // Create a new sample buffer using the copied data.
                err = CMSampleBufferCreate(
                    allocator: kCFAllocatorDefault,
                    dataBuffer: blockBufferCopy,
                    dataReady: true,
                    makeDataReadyCallback: nil,
                    refcon: nil,
                    formatDescription: formatDescription,
                    sampleCount: numSamples,
                    sampleTimingEntryCount: numSampleTimeEntries,
                    sampleTimingArray: timingArrayPointer,
                    sampleSizeEntryCount: sampleSizeEntries,
                    sampleSizeArray: sampleSize,
                    sampleBufferOut: &sampleBufferCopy
                )
                
                // Assertion to ensure the function succeeded.
                assert(err == noErr, "CMSampleBufferCreate failed \(err)")
                
                if let sampleBufferCopy {
                    // Copy metadata attachments from the original buffer to the new one.
                    CMPropagateAttachments(sampleBuffer, destination: sampleBufferCopy)
                }
                
            }
        }
        
        // Return the copied sample buffer.
        return sampleBufferCopy!
    }
}
