/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Audio Unit host for the Spatial Audio command-line interface.
*/

import AVFoundation

class AudioUnitHost {
    
    // The actual `AudioUnit`.
    public var auAudioMix = AVAudioUnitEffect()
	
    init() {
        // Generate a component description for the audio unit.
        let componentDescription = AudioComponentDescription(
            componentType: kAudioUnitType_FormatConverter,
            componentSubType: kAudioUnitSubType_AUAudioMix,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0)
		
        auAudioMix = AVAudioUnitEffect(audioComponentDescription: componentDescription)
        
    }
    
    // Set properties and parameters on `AUAudioMix` and initialize.
    func setupAUAudioMix(_ setupInput: SpatialUtility.SetupAudioMixInput) {
        enableSpatialization()
        setSpatialMixerOutputtype()
        setStreamFormat(scope: kAudioUnitScope_Input, format: setupInput.inputASBD)
        setStreamFormat(scope: kAudioUnitScope_Output, format: setupInput.outputASBD)
        
        let err = AudioUnitInitialize(auAudioMix.audioUnit)
        print("AUAudioMix - Initialize \(err != 0 ? "error \(err)" : "")")
        
        setRemixMetadata(setupInput.metadata)
        
        // Set Audio Mix parameters on `AUAudioMix`.
        setAUParameter(paramID: kAUAudioMixParameter_Style,
                       paramValue: AudioUnitParameterValue(setupInput.style.rawValue))
        
        setAUParameter(paramID: kAUAudioMixParameter_RemixAmount,
                                     paramValue: setupInput.intensity)
        
    }
    
    // Set `EnableSpatialization` property.
    func enableSpatialization() {
        var spatialization: UInt32 = 1
        let err = AudioUnitSetProperty(auAudioMix.audioUnit,
                                    kAUAudioMixProperty_EnableSpatialization,
                                    kAudioUnitScope_Global,
                                    0,
                                    &spatialization,
                                    UInt32(MemoryLayout.size(ofValue: spatialization)))
        
        print("AUAudioMix - Enable Spatialization \(err != 0 ? "error \(err)" : "")")
    }
    
    // Set `SpatialMixerOutputType` property.
    func setSpatialMixerOutputtype() {
        var spatialMixerOutputType = AUSpatialMixerOutputType.spatialMixerOutputType_ExternalSpeakers
        let err = AudioUnitSetProperty(auAudioMix.audioUnit,
                                    kAudioUnitProperty_SpatialMixerOutputType,
                                    kAudioUnitScope_Global,
                                    0,
                                    &spatialMixerOutputType,
                                    UInt32(MemoryLayout.size(ofValue: spatialMixerOutputType)))
        
        print("AUAudioMix - Set Output Type \(err != 0 ? "error \(err)" : "")")
    }

    // Set stream format property.
    func setStreamFormat(scope: UInt32, format: AudioStreamBasicDescription) {
        
        var streamFormat = format
        let err = AudioUnitSetProperty(auAudioMix.audioUnit,
                                       kAudioUnitProperty_StreamFormat,
                                       scope,
                                       0,
                                       &streamFormat,
                                       UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        
        print("AUAudioMix - Set Stream Format \(err != 0 ? "error \(err)" : "")")
    }
    
    // Set remix metadata property.
    func setRemixMetadata(_ data: CFData) {
        
        withUnsafePointer(to: data) {
            let err = AudioUnitSetProperty(auAudioMix.audioUnit,
                                        kAUAudioMixProperty_SpatialAudioMixMetadata,
                                        kAudioUnitScope_Global,
                                        0,
                                        $0,
                                        UInt32(MemoryLayout<CFData>.size))
            
            print("AUAudioMix - Set Metadata \(err != 0 ? "error \(err)" : "")")
        }
    }

    // Set `AUAudioMix` parameters.
    func setAUParameter(paramID: UInt32, paramValue: AudioUnitParameterValue) {

		let err = AudioUnitSetParameter(auAudioMix.audioUnit,
                                        paramID,
                                        kAudioUnitScope_Global,
                                        0,
                                        paramValue,
                                        0)
        
        print("AUAudioMix - Set parameter \(paramID) to value \(paramValue) \(err != 0 ? "error \(err)" : "")")
	}
    
    // Process an input FOA file with `AUAudioMix`.
    func processWithAUAudioMix(_ tmpInputURL: URL, _ outputFormat: AVAudioFormat, _ tmpOutputURL: URL) async throws {
        
        // Create .tmp file from URL to save the processed output.
        let outputTmpFile = try AVAudioFile(forWriting: tmpOutputURL, settings: outputFormat.settings)
        
        // Load input FOA .tmp file for reading.
        let tmpInputFile: AVAudioFile = try AVAudioFile(forReading: tmpInputURL)
        
        // Process the input with `AUAudioMix`.
        let frameCount: AVAudioFrameCount = 1024
        let inputBuffer = AVAudioPCMBuffer(pcmFormat: tmpInputFile.processingFormat, frameCapacity: frameCount)!
        let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCount)!
        let finalOutputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(tmpInputFile.length))!
        
        var outputFramePosition: AVAudioFrameCount = 0
        
        var timeStamp = AudioTimeStamp()
        while tmpInputFile.framePosition < tmpInputFile.length {
            try tmpInputFile.read(into: inputBuffer)
            if  inputBuffer.frameLength != frameCount { print("inputBuffer frameLength does not equal frameCount"); break }
            outputBuffer.frameLength = frameCount
            var inputBufferList = inputBuffer.audioBufferList
            var outputBufferList = outputBuffer.mutableAudioBufferList
            _ = AudioUnitProcessMultiple(auAudioMix.audioUnit, nil, &timeStamp, frameCount, 1, &inputBufferList, 1, &outputBufferList)
            
            let copyFrames = min(frameCount, finalOutputBuffer.frameCapacity - outputFramePosition)
            for channel in 0..<Int(outputFormat.channelCount) {
                let dest = finalOutputBuffer.floatChannelData![channel].advanced(by: Int(outputFramePosition))
                let src = outputBuffer.floatChannelData![channel]
                dest.update(from: src, count: Int(copyFrames))
            }
            outputFramePosition += copyFrames
            timeStamp.mSampleTime += Double(frameCount)
        }
        finalOutputBuffer.frameLength = outputFramePosition
        
        // Write the processed buffer to the output file.
        try outputTmpFile.write(from: finalOutputBuffer)
    }
}
