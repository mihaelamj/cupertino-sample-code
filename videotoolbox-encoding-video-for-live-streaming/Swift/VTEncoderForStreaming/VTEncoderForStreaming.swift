/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A Video Toolbox encoder sample app for live streaming.
*/

import AVFoundation
import VideoToolbox

/// Enumeration for encode preset.
public enum EncodePreset: Sendable {
    case balanced, highQuality, highSpeed
}

/// Enumeration for codec profile.
public enum CodecProfile: Sendable {
    case h264Main, h264High
    case hevcMain, hevcMain10
}

/// A structure that holds the configuration parameters that the person provides.
public struct Options: Sendable {
    /// The source movie file from which to read video frames.
    public let sourceMoviePath: String

    /// The destination movie file to write output video frames to.
    public let destMoviePath: String

    /// The destination movie file type.
    public let destFileType: AVFileType

    /// The maximum number of frames to encode.
    public let frameCount: Int

    /// The destination movie width.
    public let destWidth: Int

    /// The destination movie height.
    public let destHeight: Int

    /// The destination movie target bit rate in bits per second.
    public let destBitRate: Int?

    /// The codec type to encode with.
    public let codec: CMVideoCodecType

    /// The `CodecProfile` enumeration and profile name.
    public let profileTuple: (CodecProfile, String)?

    /// The `EncodePreset` enumeration and preset name.
    public let presetTuple: (EncodePreset, String)?

    /// The pixel format to encode with.
    public let pixelFormat: OSType
    
    /// The maximum key frame interval in seconds.
    public let maxKeyFrameIntervalDuration: Double?

    /// The maximum key frame interval in number of frames.
    public let maxKeyFrameInterval: Int?

    /// The number of frames to use for additional analysis.
    public let lookAheadFrames: Int?

    /// Control spatial adaptation of the quantization parameter based on per-frame statistics.
    public let spatialAdaptiveQP: Int?

    /// A Boolean value that specifies whether to pad the encoded frame for constant bit rate.
    public let constantBitRateMode: Bool

    /// Print noisy status if `true`.
    public let verbose: Bool

    /// Replace the destination movie file if it already exists, if `true`.
    public let replace = true

    /// A read-only property that shows the configuration values person provides.
    public var description: String {
        let bitRate = if let destBitRate {
            "\(destBitRate) bps"
        } else {
            "not set"
        }

        let keyFrameIntervalDuration = if let maxKeyFrameIntervalDuration {
            "\(maxKeyFrameIntervalDuration) sec"
        } else {
            "not set"
        }

        let keyFrameInterval = if let maxKeyFrameInterval {
            "\(maxKeyFrameInterval) frames"
        } else {
            "not set"
        }

        let lookAhead = if let lookAheadFrames {
            "\(lookAheadFrames) frames"
        } else {
            "not set"
        }

        let presetName = if let presetTuple {
            presetTuple.1
        } else {
            "not set"
        }

        let profileName = if let profileTuple {
            profileTuple.1
        } else {
            "not set"
        }

        let spatialAdaptiveQPLevel = switch spatialAdaptiveQP {
        case nil:
            "not set"
        case kVTQPModulationLevel_Default:
            "default"
        case kVTQPModulationLevel_Disable:
            "disabled"
        default:
            "unknown (\(spatialAdaptiveQP!))"
        }

        return """
            source-movie          : \(sourceMoviePath)
            --bitrate             : \(bitRate)
            --cbr                 : \(constantBitRateMode)
            --codec               : \(fourCCToString(codec) ?? "")
            --dimensions          : \(destWidth) x \(destHeight)
            --frames              : \(frameCount == .max ? "all" : "\(frameCount)") frames
            --keyframe-duration   : \(keyFrameIntervalDuration)
            --keyframe-interval   : \(keyFrameInterval)
            --look-ahead-frames   : \(lookAhead)
            --out                 : \(destMoviePath)
            --pixel-format        : \(fourCCToString(pixelFormat) ?? "")
            --profile             : \(profileName)
            --preset              : \(presetName)
            --spatial-adaptive-qp : \(spatialAdaptiveQPLevel)
        """
    }

    /// Create an instance of `Options`.
    /// - Parameters:
    ///   - sourceMoviePath: The file path of the source movie file.
    ///   - destMoviePath: The file path of the destination movie file.
    ///   - destFileType: The destination movie file type.
    ///   - frameCount: The maximum number of frames to encode.
    ///   - destWidth: The destination movie width.
    ///   - destHeight: The destination movie height.
    ///   - destBitRate: The destination movie bit rate in bits per second.
    ///   - codec: The codec type to encode the movie with.
    ///   - profile: `CodecProfile` enumeration and name.
    ///   - preset: `EncodePreset` enumeration and name.
    ///   - pixelFormat: The pixel format of the uncompressed image to encode.
    ///   - maxKeyFrameIntervalDuration: The maximum key frame interval in seconds.
    ///   - maxKeyFrameInterval: The maximum key frame interval in number of frames.
    ///   - lookAheadFrames: The number of frames to look ahead.
    ///   - spatialAdaptiveQP: The spatial adaptive QP mode.
    ///   - constantBitRateMode: A Boolean value that specifies whether to pad the encoded frame for constant bit rate.
    ///   - verbose: A Boolean value that specifies whether to print frame information.
    public init(sourceMoviePath: String,
                destMoviePath: String,
                destFileType: AVFileType,
                frameCount: Int = .max,
                destWidth: Int,
                destHeight: Int,
                destBitRate: Int?,
                codec: CMVideoCodecType,
                profileTuple: (CodecProfile, String)?,
                presetTuple: (EncodePreset, String)?,
                pixelFormat: OSType,
                maxKeyFrameIntervalDuration: Double?,
                maxKeyFrameInterval: Int?,
                lookAheadFrames: Int?,
                spatialAdaptiveQP: Int?,
                constantBitRateMode: Bool,
                verbose: Bool) {
        self.sourceMoviePath = sourceMoviePath
        self.destMoviePath = destMoviePath
        self.destFileType = destFileType
        self.frameCount = frameCount
        self.destWidth = destWidth
        self.destHeight = destHeight
        self.destBitRate = destBitRate
        self.codec = codec
        self.profileTuple = profileTuple
        self.presetTuple = presetTuple
        self.pixelFormat = pixelFormat
        self.maxKeyFrameIntervalDuration = maxKeyFrameIntervalDuration
        self.maxKeyFrameInterval = maxKeyFrameInterval
        self.lookAheadFrames = lookAheadFrames
        self.spatialAdaptiveQP = spatialAdaptiveQP
        self.constantBitRateMode = constantBitRateMode
        self.verbose = verbose
    }
}

/// Get the suggested encoder settings dictionary for encode preset.
/// - Parameters:
///   - session: A compression session.
///   - encodePreset: The `EncodePreset` enumeration.
private func getEncoderSettingsForPreset(session: VTCompressionSession, encodePreset: EncodePreset) -> [CFString: Any]? {
    var supportedPresetDictionaries: CFDictionary?
    var encoderSettings: [CFString: Any]?

    _ = withUnsafeMutablePointer(to: &supportedPresetDictionaries) { valueOut in
        VTSessionCopyProperty( session, key: kVTCompressionPropertyKey_SupportedPresetDictionaries,
                               allocator: kCFAllocatorDefault, valueOut: valueOut )
    }

    if let presetDictionaries = supportedPresetDictionaries as? [CFString: [CFString: Any]] {
        let presetConstant = switch encodePreset {
        case .balanced: kVTCompressionPreset_Balanced
        case .highQuality: kVTCompressionPreset_HighQuality
        case .highSpeed: kVTCompressionPreset_HighSpeed
        }

        encoderSettings = presetDictionaries[presetConstant]
    }

    return encoderSettings
}

/// Configures a compression session for live streaming.
/// - Parameters:
///   - session: A compression session.
///   - options: The configuration options.
///   - expectedFrameRate: The expected frame rate of the video source.
private func configureVTCompressionSession(session: VTCompressionSession, options: Options, expectedFrameRate: Float) throws {
    // Different encoder implementations may support different property sets, so
    // the app needs to determine the implications of a failed property setting
    // on a case-by-case basis for the encoder. If the property is essential for
    // the use case and its setting fails, the app terminates. Otherwise, the
    // encoder ignores the failed setting and uses a default value to proceed
    // with encoding.

    var err: OSStatus = noErr
    var variableBitRateMode = false

    if let presetTuple = options.presetTuple {
        // Try configuring the encoder using the preset.
        let encoderSettings: [CFString: Any]?
        encoderSettings = getEncoderSettingsForPreset(session: session, encodePreset: presetTuple.0)

        if let encoderSettings {
            if encoderSettings[kVTCompressionPropertyKey_VariableBitRate] != nil {
                variableBitRateMode = true
            }

            // Set the encoder settings dictionary on the compression session.
            err = VTSessionSetProperties(session, propertyDictionary: encoderSettings as CFDictionary)
            try NSError.check(err, "VTSessionSetProperties failed")
        }
    }

    // Indicate real time compression session, which live streaming requires.
    err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
    if err != noErr {
        print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_RealTime) failed (\(err))")
    }

    // Indicate the expected frame rate, if known. This is just a hint for rate
    // control purposes; the actual encoding frame rate matches the incoming
    // frame rate even if it doesn't match this setting. When
    // `kVTCompressionPropertyKey_RealTime` is `kCFBooleanTrue`, the video
    // encoder may optimize energy usage.
    err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: expectedFrameRate as CFNumber)
    if err != noErr {
        print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_ExpectedFrameRate) failed (\(err))")
    }

    // Specify the profile and level for the encoded bitstream.
    if let profileTuple = options.profileTuple {
        var profileConstant: CFString?

        if options.codec == kCMVideoCodecType_H264 {
            if profileTuple.0 == .h264Main {
                profileConstant = kVTProfileLevel_H264_Main_AutoLevel
            } else if profileTuple.0 == .h264High {
                profileConstant = kVTProfileLevel_H264_High_AutoLevel
            }
        } else if options.codec == kCMVideoCodecType_HEVC {
            if profileTuple.0 == .hevcMain {
                profileConstant = kVTProfileLevel_HEVC_Main_AutoLevel
            } else if profileTuple.0 == .hevcMain10 {
                profileConstant = kVTProfileLevel_HEVC_Main10_AutoLevel
            }
        }

        if let profileConstant {
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel, value: profileConstant)
            if err != noErr {
                print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_ProfileLevel) failed (\(err))")
            }
        }
    }

    if let destBitRate = options.destBitRate {
        if options.constantBitRateMode {
            // This is intended for legacy content distribution networks
            // that require constant bitrate, not for general streaming
            // scenarios. The encoder pads the frames if they are smaller
            // than necessary based on the constant bit rate.
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ConstantBitRate, value: destBitRate as CFNumber)
            if err != noErr {
                print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_ConstantBitRate) failed (\(err))")
            }
        } else if variableBitRateMode {
            // Specify the long-term desired variable bit rate in bits per second.
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_VariableBitRate, value: destBitRate as CFNumber)
            if err != noErr {
                print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_VariableBitRate) failed (\(err))")
            }

            // Set VBV maximum bit rate.
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_VBVMaxBitRate, value: (destBitRate * 3 / 2) as CFNumber)
            if err != noErr {
                print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_VBVMaxBitRate) failed (\(err))")
            }
        } else {
            // Specify the long-term desired average bit rate in bits per second.
            // It's a soft limit, so the encoder may overshoot or undershoot and
            // the average bit rate of the output video may be over or under the
            // target.
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: destBitRate as CFNumber)
            if err != noErr {
                print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_AverageBitRate) failed (\(err))")
            }
            
            // Specify a hard data-rate cap for a given time window, which
            // the encoder won't overshoot. Use
            // `kVTCompressionPropertyKey_AverageBitRate` and
            // `kVTCompressionPropertyKey_DataRateLimits` together to
            // specify an overall target bit rate and hard limits over a
            // smaller window.
            let byteLimit = (Double(destBitRate) / 8 * 1.5) as CFNumber
            let secLimit = Double(1.0) as CFNumber
            let limitsArray = [ byteLimit, secLimit ] as CFArray
            err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_DataRateLimits, value: limitsArray)
            if err != noErr {
                print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_DataRateLimits) failed (\(err))")
            }
        }
    }

    if let maxKeyFrameInterval = options.maxKeyFrameInterval {
        // Specify the maximum interval between key frames, also known as
        // the key frame rate. Set this in conjunction with
        // `kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration` to
        // enforce both limits, which requires a keyframe every X frames
        // or every Y seconds, whichever comes first.
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: maxKeyFrameInterval as CFNumber)
        if err != noErr {
            print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_MaxKeyFrameInterval) failed (\(err))")
        }
    }

    if let maxKeyFrameIntervalDuration = options.maxKeyFrameIntervalDuration {
        // Specify the maximum duration from one key frame to the next in seconds.
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration,
                                   value: maxKeyFrameIntervalDuration as CFNumber)
        if err != noErr {
            print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration) failed (\(err))")
        }
    }

    if let lookAheadFrames = options.lookAheadFrames {
        // Specify the number of look ahead frames.
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_SuggestedLookAheadFrameCount, value: lookAheadFrames as CFNumber)
        if err != noErr {
            print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_SuggestedLookAheadFrameCount) failed (\(err))")
        }
    }

    if let spatialAdaptiveQP = options.spatialAdaptiveQP {
        // Specify whether to apply spatial QP adaptation based on per-frame
        // statistics.
        err = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_SpatialAdaptiveQPLevel, value: spatialAdaptiveQP as CFNumber)
        if err != noErr {
            print("Warning: VTSessionSetProperty(kVTCompressionPropertyKey_SpatialAdaptiveQPLevel) failed (\(err))")
        }
    }
}

/// Process video for live streaming.
/// - Parameter options: The configuration options.
public func processVideoStreaming(options: Options) async throws {
    // The compression task feeds compressed frames into the
    // `outputContinuation`, and the file writing loop reads compressed frames
    // from the `compressedFrameSequence` below.
    var escapedContinuation: AsyncStream<(OSStatus, VTEncodeInfoFlags, CMSampleBuffer?, Int)>.Continuation!
    let compressedFrameSequence = AsyncStream<(OSStatus, VTEncodeInfoFlags, CMSampleBuffer?, Int)> { escapedContinuation = $0 }
    let outputContinuation = escapedContinuation!

    // Kick off a task to feed source video frames to the compression session.
    // This needs to happen concurrently with the execution of this function so
    // that compressed frames are written to the output file as they become
    // available.
    let compressionTask = Task {
        // Set `alwaysCopiesSampleData` to `false` to specify that this app
        // doesn't modify the output `CVImageBuffer` sample data. Set it to
        // `true` if the app modifies the output `CVImageBuffer` sample data.
        let videoSource = RealTimeVideoSource(filePath: options.sourceMoviePath,
                                              outputPixelFormat: options.pixelFormat,
                                              alwaysCopiesSampleData: false)
        let sourceInfo = try await videoSource.sourceInfo

        try await compressFrames(from: videoSource,
                                 options: options,
                                 expectedFrameRate: sourceInfo.frameRate,
                                 outputHandler: {
            (status, infoFlags, sbuf, frameNumber) in
            outputContinuation.yield((status, infoFlags, sbuf, frameNumber))
        })
        outputContinuation.finish()

        return sourceInfo
    }

    if options.replace {
        // Delete the destination movie file if it already exists.
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: options.destMoviePath) {
            try fileManager.removeItem(atPath: options.destMoviePath)
        }
    }

    // Send compressed frames to a video sink.
    let videoSink = try VideoSink(filePath: options.destMoviePath,
                                  fileType: options.destFileType,
                                  codec: options.codec,
                                  width: options.destWidth,
                                  height: options.destHeight,
                                  isRealTime: true)
    var destEndPTS = CMTime.zero
    var encodedFrameCount = 0

    for try await (status, infoFlags, sbuf, sourceFrameNumber) in compressedFrameSequence {
        if infoFlags.contains(.frameDropped) {
            print("Encoder dropped the frame \(sourceFrameNumber) with status \(status)")
            continue
        }
        // If frame encoding fails in a live streaming use case, drop any
        // pending frames that the encoder may emit and force a key frame.
        // For information about forcing a key frame, see
        // `kVTEncodeFrameOptionKey_ForceKeyFrame`
        // This sample app doesn't include this implementation.
        guard status == noErr else {
            print("Encoder returned an error for frame \(sourceFrameNumber) with \(status)")
            break
        }
        guard let sbuf else {
            print("Encoder returned an unexpected NULL sampleBuffer for frame \(sourceFrameNumber)")
            break
        }

        let pts = sbuf.presentationTimeStamp

        encodedFrameCount += 1
        if destEndPTS < pts {
            destEndPTS = pts
        }

        if options.verbose {
            let dts = sbuf.decodeTimeStamp
            let sampleSizes = try sbuf.sampleSizes()
            NSLog("compressionOutput for frame %llu [PTS: %.3f DTS: %.3f size: %zu]", sourceFrameNumber, pts.seconds, dts.seconds, sampleSizes[0])
        }

        videoSink.sendSampleBuffer(sbuf)
    }

    // Await completion of compression task and retrieve source info.
    let sourceInfo = try await compressionTask.value

    let destDuration: CMTime
    if encodedFrameCount > 0 {
        destDuration = destEndPTS + CMTime(seconds: 1.0 / Double(sourceInfo.frameRate), preferredTimescale: 600)
    } else {
        destDuration = CMTime.invalid
    }

    try await videoSink.close()

    print("""

        Summary
            Source movie dimensions         : \(sourceInfo.width) x \(sourceInfo.height)
            Destination movie dimensions    : \(options.destWidth) x \(options.destHeight)
            Destination movie # of frames   : \(encodedFrameCount) frames
        """)
    if encodedFrameCount > 0 {
        print(String(format: "    Destination movie duration      : %.2f sec", destDuration.seconds))
    }
    print("")
}

/// Compress video frames.
/// - Parameters:
///   - videoSource: Video source that delivers uncompressed video frames.
///   - options: Configuration parameters in an `Options` instance.
///   - expectedFrameRate: The expected frame rate of the video source.
///   - outputHandler: A closure to call once per encoded frame.
private func compressFrames(from videoSource: RealTimeVideoSource,
                            options: Options,
                            expectedFrameRate: Float,
                            outputHandler: @Sendable @escaping (OSStatus, VTEncodeInfoFlags, CMSampleBuffer?, Int) -> Void) async throws {
    // Specify the pixel format of the uncompressed video.
    let sourceImageBufferAttributes = [kCVPixelBufferPixelFormatTypeKey: options.pixelFormat as CFNumber] as CFDictionary

    var compressionSessionOut: VTCompressionSession?
    let err = VTCompressionSessionCreate(allocator: kCFAllocatorDefault,
                                         width: Int32(options.destWidth),
                                         height: Int32(options.destHeight),
                                         codecType: options.codec,
                                         encoderSpecification: nil,
                                         imageBufferAttributes: sourceImageBufferAttributes,
                                         compressedDataAllocator: nil,
                                         outputCallback: nil,
                                         refcon: nil,
                                         compressionSessionOut: &compressionSessionOut)
    guard err == noErr, let compressionSession = compressionSessionOut else {
        throw RuntimeError("VTCompressionSession creation failed (\(err))!")
    }
    try configureVTCompressionSession(session: compressionSession, options: options, expectedFrameRate: expectedFrameRate)

    var sourceFrameNumber = 0

    // Compress video frames in each image buffer.
    for try await (imageBuffer, pts) in videoSource.frames(frameCount: options.frameCount) {
        sourceFrameNumber += 1
        let thisFrameNumber = sourceFrameNumber

        if options.verbose {
            NSLog("compressFrame %llu [PTS: %.3f]", thisFrameNumber, pts.seconds)
        }

        let err = VTCompressionSessionEncodeFrame(compressionSession,
                                                  imageBuffer: imageBuffer,
                                                  presentationTimeStamp: pts,
                                                  duration: .invalid,
                                                  frameProperties: nil,
                                                  infoFlagsOut: nil) {
            (status: OSStatus, infoFlags: VTEncodeInfoFlags, sbuf: CMSampleBuffer?) -> Void in
            outputHandler(status, infoFlags, sbuf, thisFrameNumber)
        }
        guard err == noErr else {
            // If frame encoding fails in a live streaming use case, drop any
            // pending frames that the encoder may emit and force a key frame.
            // For information about forcing a key frame, see `kVTEncodeFrameOptionKey_ForceKeyFrame`.
            // This sample app doesn't include this implementation.
            print("Error: VTCompressionSessionEncodeFrame failed! (\(err))")
            continue
        }
    }

    // Force the compression session to complete the encoding of frames and
    // emit all pending frames.
    VTCompressionSessionCompleteFrames(compressionSession, untilPresentationTimeStamp: .invalid)
}

extension NSError {
    static func check(_ status: OSStatus, _ message: String? = nil) throws {
        guard status == noErr else {
            if let message {
                print("\(message), err: \(status)")
            }
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
}
