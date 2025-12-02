/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A Video Toolbox encoder sample app for live streaming.
*/

#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "VideoSource.h"
#import "VideoSink.h"
#import "VTEncoderUtil.h"
#import "VTEncoderForStreaming.h"

/// A structure that models a video encoding session.
typedef struct {
    /// The biggest presentation time stamp of the encoded frames.
    CMTime destEndPTS;
    /// A counter that indicates the number of frames the encoder received.
    uint64_t sourceFrameCounter;
    // A counter that indicates the number of encoded frames.
    uint64_t encodedFrameCount;
    /// Print noisy status if `true`.
    BOOL verbose;
} CompressionState;

/// A structure that models a video frame to encode.
typedef struct {
    /// The presentation time stamp of the frame.
    CMTime pts;
    /// The number that identifies the display order of the frame.
    uint64_t frameNumber;
} FrameState;

static void compressionOutput(OSStatus status,
                              VTEncodeInfoFlags infoFlags,
                              CMSampleBufferRef sbuf,
                              FrameState *frame,
                              CompressionState *state,
                              VideoSink *videoSink)
{
    if(infoFlags & kVTEncodeInfo_FrameDropped) {
        fprintf(stderr, "Encoder dropped the frame %llu, sbuf %p (error: %d)\n", frame->frameNumber, sbuf, (int)status);
        return;
    }

    // If frame encoding fails in a streaming use case, drop any pending
    // frames that may be emitted and force a key frame. For information 
    // about forcing a key frame, see `kVTEncodeFrameOptionKey_ForceKeyFrame`.
    // This sample app doesn't include this implementation.
    if(status != noErr) {
        fprintf(stderr, "Encoder returned an error for frame %llu, sbuf %p (error: %d)\n", frame->frameNumber, sbuf, (int)status);
        return;
    }
    if(! sbuf) {
        fprintf(stderr, "Encoder returned an unexpected NULL sampleBuffer for frame %llu\n", frame->frameNumber);
        return;
    }

    state->encodedFrameCount++;
    if(CMTimeCompare(state->destEndPTS, frame->pts) < 0) {
        state->destEndPTS = frame->pts;
    }

    if(state->verbose) {
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sbuf);
        CMTime dts = CMSampleBufferGetDecodeTimeStamp(sbuf);

        NSLog(@"compressionOutput for frame %llu [PTS:%1.3f, DTS:%1.3f, size:%zu]\n", frame->frameNumber, CMTimeGetSeconds(pts), CMTimeGetSeconds(dts), CMSampleBufferGetSampleSize(sbuf, 0));
    }

    [videoSink sendSampleBuffer:sbuf];
}

/// Compress video frame.
/// - Parameters:
///   - imageBuffer: An image buffer.
///   - pts: A presentation time stamp.
///   - state: A state for the compression session.
///   - compressionSession: A compression session.
///   - videoSink: A video sink.
static void compressFrame(CVImageBufferRef imageBuffer,
                          CMTime pts,
                          CompressionState *state,
                          VTCompressionSessionRef compressionSession,
                          VideoSink *videoSink)
{
    __block VideoSink *videoSinkCopy = videoSink;
    OSStatus err = noErr;
    BOOL releaseFrame = false;
    FrameState *frame = NULL;

    frame = calloc(1, sizeof(FrameState));
    frame->frameNumber = state->sourceFrameCounter++;
    frame->pts = pts;

    if(state->verbose) {
        NSLog(@"compressFrame %llu [PTS:%1.3f]", frame->frameNumber, CMTimeGetSeconds(frame->pts));
    }

    err = VTCompressionSessionEncodeFrameWithOutputHandler(compressionSession,
                                                           imageBuffer,
                                                           frame->pts,
                                                           kCMTimeInvalid,
                                                           NULL,
                                                           NULL,
                                                           ^(OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sbuf) {
        compressionOutput(status, infoFlags, sbuf, frame, state, videoSinkCopy);
        free(frame);
    });
    if(err != noErr) {
        // If frame encoding fails in a live streaming use case, drop any pending
        // frames that may be emitted and force a key frame.
        // For information about forcing a key frame, see 
        // `kVTEncodeFrameOptionKey_ForceKeyFrame`.
        // This sample app doesn't include this implementation.
        releaseFrame = true;
        fprintf(stderr, "VTCompressionSessionEncodeFrame failed! (%d)\n", err);
        goto bail;
    }

bail:
    if(releaseFrame) {
        free(frame);
    }
}

/// Try setting an encode preset on the compression session.
/// - Parameters:
///   - session: A compression session.
///   - preset: The encode preset.
///   - variableBitRateMode: An output for suggested bit rate mode.
static OSStatus trySettingVTCompressionPreset(VTCompressionSessionRef session,
                                              CFStringRef preset,
                                              BOOL *variableBitRateMode )
{
    // Don't return error if preset is not specified,
    // if encoder doesn't support preset dictionaries,
    // or if encoder doesn't support the specified preset.

    OSStatus err = noErr;
    CFDictionaryRef supportedCompressionPresets = NULL;
    CFDictionaryRef encoderSettings = NULL;

    if(preset == NULL) {
        goto bail;
    }

    // Copy the supported preset dictionaries.
    err = VTSessionCopyProperty( session, kVTCompressionPropertyKey_SupportedPresetDictionaries, kCFAllocatorDefault, &supportedCompressionPresets );
    if(err != noErr) {
        fprintf(stderr, "VTSessionCopyProperty(kVTCompressionPropertyKey_SupportedPresetDictionaries) failed (%d)\n", (int)err);
        err = noErr;
        goto bail;
    }
    if(! supportedCompressionPresets) {
        fprintf( stderr, "Preset dictionaries is NULL.\n" );
        goto bail;
    }

    // Get the encoder settings dictionary for the preset.
    encoderSettings = (CFDictionaryRef)CFDictionaryGetValue(supportedCompressionPresets, preset);
    if(! encoderSettings) {
        fprintf( stderr, "preset is not supported.\n" );
        goto bail;
    }

    // Determine if the encoder settings dictionary uses variable bit rate.
    if(CFDictionaryContainsKey(encoderSettings, kVTCompressionPropertyKey_VariableBitRate)) {
        *variableBitRateMode = true;
    } else {
        *variableBitRateMode = false;
    }

    // Set the encoder settings dictionary on the compression session.
    // Return error if this fails.
    err = VTSessionSetProperties(session, encoderSettings);
    if(err != noErr) {
        fprintf( stderr, "VTSessionSetProperties failed (%d)\n", (int)err );
    }

bail:
    if(supportedCompressionPresets)
        CFRelease(supportedCompressionPresets);
    return err;
}

/// Configures a compression session for live streaming.
/// - Parameters:
///   - session: A compression session.
///   - options: The configuration options.
///   - expectedFrameRate: The expected frame rate of the video source.
static OSStatus configureVTCompressionSession(VTCompressionSessionRef session,
                                          Options *options,
                                          float expectedFrameRate)
{
    // Different encoder implementations may support different property sets, so
    // the app needs to determine the implications of a failed property setting
    // on a case-by-case basis for the encoder. If the property is essential for
    // the use case and its setting fails, the app terminates. Otherwise, the
    // encoder ignores the failed setting and uses a default value to proceed
    // with encoding.

    OSStatus err = noErr;
    OSStatus localErr = noErr;
    BOOL variableBitRateMode = false;

    // Try configuring the encoder using an encode preset.
    err = trySettingVTCompressionPreset(session, options->preset, &variableBitRateMode);
    if(err != noErr) {
        goto bail;
    }

    // Use `VTSessionSetProperty` to set additional compression session properties
    // one by one so that it's easier to detect a failure.

    // Indicate real time compression session, which live streaming requires.
    localErr = VTSessionSetProperty(session, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    if(localErr != noErr) {
        fprintf(stderr, "VTSessionSetProperty(kVTCompressionPropertyKey_RealTime) failed (%d)\n", (int)localErr);
    }

    // Indicate the expected frame rate, if known. This is just a hint for rate
    // control purposes; the actual encoding frame rate matches the incoming
    // frame rate even if it doesn't match this setting. When
    // `kVTCompressionPropertyKey_RealTime` is `kCFBooleanTrue`, the video
    // encoder may optimize energy usage.
    {
        CFNumberRef frameRateNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &expectedFrameRate);
        localErr = VTSessionSetProperty(session, kVTCompressionPropertyKey_ExpectedFrameRate, frameRateNumber);
        if(localErr != noErr) {
            fprintf(stderr, "VTSessionSetProperty(kVTCompressionPropertyKey_ExpectedFrameRate) failed (%d)\n", (int)localErr);
        }
        CFRelease(frameRateNumber);
    }

    // Specify the profile and level for the encoded bitstream.
    if(options->profile != NULL) {
        localErr = VTSessionSetProperty(session, kVTCompressionPropertyKey_ProfileLevel, options->profile);
        if(localErr != noErr) {
            fprintf(stderr, "VTSessionSetProperty(kVTCompressionPropertyKey_ProfileLevel) failed (%d)\n", (int)localErr);
        }
    }

    if(options->destBitRate > 0) {
        if(options->constantBitRateMode) {
            // This is intended for legacy content distribution networks which
            // require constant bitrate, not for general streaming scenarios. The
            // encoder pads the frame if they are smaller than necessary based on
            // the constant bit rate.
            CFNumberRef bitRateNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &options->destBitRate);
            localErr = VTSessionSetProperty(session, kVTCompressionPropertyKey_ConstantBitRate, bitRateNumber);
            if(localErr != noErr) {
                fprintf(stderr, "VTSessionSetProperty(kVTCompressionPropertyKey_ConstantBitRate) failed (%d)\n", (int)localErr);
            }
            CFRelease(bitRateNumber);
        }
        else if(variableBitRateMode) {
            // Specify the long-term desired variable bit rate in bits per second.
            {
                CFNumberRef bitRateNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &options->destBitRate);
                localErr = VTSessionSetProperty(session, kVTCompressionPropertyKey_VariableBitRate, bitRateNumber);
                if(localErr != noErr) {
                    fprintf(stderr, "VTSessionSetProperty(kVTCompressionPropertyKey_VariableBitRate) failed (%d)\n", (int)localErr);
                }
                CFRelease(bitRateNumber);
            }

            // Set VBV maximum bit rate.
            {
                int32_t VBVMaxBitRate = options->destBitRate * 3 / 2;
                CFNumberRef VBVMaxBitRateNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &VBVMaxBitRate);

                localErr = VTSessionSetProperty(session, kVTCompressionPropertyKey_VBVMaxBitRate, VBVMaxBitRateNumber);
                if(localErr != noErr) {
                    fprintf(stderr, "VTSessionSetProperty(kVTCompressionPropertyKey_VBVMaxBitRate) failed (%d)\n", (int)localErr);
                }
                CFRelease(VBVMaxBitRateNumber);
            }
        }
        else {
            // Specify the long-term desired average bit rate in bits per second.
            // It's a soft limit, so the encoder may overshoot or undershoot and
            // the average bit rate of the output video may be over or under the
            // target.
            {
                CFNumberRef bitRateNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &options->destBitRate);
                localErr = VTSessionSetProperty(session, kVTCompressionPropertyKey_AverageBitRate, bitRateNumber);
                if(localErr != noErr) {
                    fprintf(stderr, "VTSessionSetProperty(kVTCompressionPropertyKey_AverageBitRate) failed (%d)\n", (int)localErr);
                }
                CFRelease(bitRateNumber);
            }
            
            // Specify a hard data rate cap for a given time window, which the
            // encoder won't overshoot. Use `kVTCompressionPropertyKey_AverageBitRate`
            // and `kVTCompressionPropertyKey_DataRateLimits` together to specify an
            // overall target bit rate and hard limits over a smaller window.
            {
                CFArrayRef limitsArray;
                CFNumberRef limits[2];
                Float64 byteLimit = options->destBitRate / 8 * 1.5;
                Float64 secLimit = 1.0;
                
                limits[0] = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloat64Type, &byteLimit);
                limits[1] = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloat64Type, &secLimit);
                limitsArray = CFArrayCreate(kCFAllocatorDefault, (const void **) &limits, 2, &kCFTypeArrayCallBacks);
                
                localErr = VTSessionSetProperty(session, kVTCompressionPropertyKey_DataRateLimits, limitsArray);
                if(localErr != noErr) {
                    fprintf(stderr, "VTSessionSetProperty(kVTCompressionPropertyKey_DataRateLimits) failed (%d)\n", (int)localErr);
                }
                CFRelease(limits[0]);
                CFRelease(limits[1]);
                CFRelease(limitsArray);
            }
        }
    }

    if(options->maxKeyFrameInterval > 0) {
        // Specify the maximum interval between key frames, also known as
        // the key frame rate. Set this in conjunction with
        // `kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration` to
        // enforce both limits, which requires a keyframe every X frames
        // or every Y seconds, whichever comes first.
        CFNumberRef intervalNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &options->maxKeyFrameInterval);
        localErr = VTSessionSetProperty(session, kVTCompressionPropertyKey_MaxKeyFrameInterval, intervalNumber);
        if(localErr != noErr) {
            fprintf(stderr, "VTSessionSetProperty(kVTCompressionPropertyKey_MaxKeyFrameInterval) failed (%d)\n", (int)localErr);
        }
        CFRelease(intervalNumber);
    }

    if(options->maxKeyFrameIntervalDuration > 0) {
        // Specify the maximum duration from one key frame to the next in seconds.
        CFNumberRef durationNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloat64Type, &options->maxKeyFrameIntervalDuration);
        localErr = VTSessionSetProperty(session, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, durationNumber);
        if(localErr != noErr) {
            fprintf(stderr, "VTSessionSetProperty(kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration) failed (%d)\n", (int)localErr);
        }
        CFRelease(durationNumber);
    }

    if(options->lookAheadFramesIsSet) {
        // Specify the number of look ahead frames.
        CFNumberRef lookAheadFramesNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &options->lookAheadFrames);
        localErr = VTSessionSetProperty(session, kVTCompressionPropertyKey_SuggestedLookAheadFrameCount, lookAheadFramesNumber);
        if(localErr != noErr) {
            fprintf(stderr, "VTSessionSetProperty(kVTCompressionPropertyKey_SuggestedLookAheadFrameCount) failed (%d)\n", (int)localErr);
        }
        CFRelease(lookAheadFramesNumber);
    }

    if(options->spatialAdaptiveQPIsSet) {
        // Specify whether to apply spatial QP adaptation based on per-frame statistics.
        CFNumberRef spatialAdaptiveQPNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &options->spatialAdaptiveQP);
        localErr = VTSessionSetProperty(session, kVTCompressionPropertyKey_SpatialAdaptiveQPLevel, spatialAdaptiveQPNumber);
        if(localErr != noErr) {
            fprintf(stderr, "VTSessionSetProperty(kVTCompressionPropertyKey_SpatialAdaptiveQPLevel) failed (%d)\n", (int)localErr);
        }
        CFRelease(spatialAdaptiveQPNumber);
    }

bail:
    return err;
}

/// Process video for live streaming.
/// - Parameter options: The configuration options.
OSStatus processVideoStreaming(Options *options)
{
    OSStatus err = noErr;
    VideoSource *videoSource = NULL;
    __block VideoSink *videoSink = NULL;
    VTCompressionSessionRef compressionSession = NULL;
    CompressionState myState = {0}, *state = &myState;
    CFMutableDictionaryRef sourceImageBufferAttributes = NULL;
    CMTime destDuration = kCMTimeInvalid;

    if(! options) {
        err = -101;
        goto bail;
    }

    state->sourceFrameCounter = 1;
    state->destEndPTS = kCMTimeZero;
    state->verbose = options->verbose;

    // Set `alwaysCopiesSampleData` to `false` to specify that this app
    // doesn't modify the output `CVImageBuffer` sample data. Set it to
    // `true` if the app modifies the output `CVImageBuffer` sample data.
    videoSource = [RealTimeVideoSource videoSourceWithFile:options->sourceMoviePath
                                         outputPixelFormat:options->pixelFormat
                                    alwaysCopiesSampleData:false];
    if(videoSource == nil) {
        fprintf(stderr, "Error: videoSourceWithFile failed for source file \'%s\'\n", options->sourceMoviePath);
        err = -101;
        goto bail;
    }

    sourceImageBufferAttributes = (__bridge CFMutableDictionaryRef)
        [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInteger:options->pixelFormat], kCVPixelBufferPixelFormatTypeKey, nil];
    if(!sourceImageBufferAttributes) {
        fprintf(stderr, "Error: sourceImageBufferAttributes creation failed\n");
        err = -101;
        goto bail;
    }

    err = VTCompressionSessionCreate(kCFAllocatorDefault,
                                     options->destWidth,
                                     options->destHeight,
                                     options->codec,
                                     NULL,
                                     sourceImageBufferAttributes,
                                     NULL,
                                     NULL,
                                     NULL,
                                     &compressionSession);
    if((err != noErr) || (! compressionSession)) {
        fprintf(stderr, "Error: VTCompressionSessionCreate failed, error = [%d]\n", err);
        goto bail;
    }

    err = configureVTCompressionSession(compressionSession, options, videoSource.frameRate);
    if(err != noErr) {
        goto bail;
    }

    if(options->replace) {
        unlink(options->destMoviePath);
    }

    // Send compressed frames to a video sink.
    videoSink = [VideoSink videoSinkWithFile:options->destMoviePath
                                    fileType:options->destFileType
                                   codecType:options->codec
                                  videoWidth:options->destWidth
                                 videoHeight:options->destHeight
                                    realTime:true];
    if(videoSink == nil) {
        fprintf(stderr, "Error: videoSinkWithFile failed for destination file \'%s\'\n", options->destMoviePath);
        err = -101;
        goto bail;
    }

    err = [videoSource run:(uint64_t)options->frameCount
             frameCallback:^(CVImageBufferRef imageBuffer, CMTime pts) {
        compressFrame(imageBuffer, pts, state, compressionSession, videoSink);
        CVPixelBufferRelease(imageBuffer);
    }];
    if(err != noErr) {
        fprintf(stderr, "Error: VideoSource run failed, error = [%d]\n", err);
        goto bail;
    }

    // Force the compression session to complete the encoding of frames and
    // emit all pending frames.
    VTCompressionSessionCompleteFrames(compressionSession, kCMTimeInvalid);

    if((state->encodedFrameCount > 0) && (videoSource.frameRate > 0)) {
        destDuration = CMTimeAdd(state->destEndPTS, CMTimeMakeWithSeconds(1.0 / videoSource.frameRate, 600));
    }

    fprintf(stderr, "\nSummary\n");
    fprintf(stderr, "\tSource movie dimensions         : %d x %d\n", videoSource.width, videoSource.height);
    fprintf(stderr, "\tDestination movie dimensions    : %d x %d\n", options->destWidth, options->destHeight);
    fprintf(stderr, "\tDestination movie # of frames   : %llu frames\n", state->encodedFrameCount);
    if(CMTIME_IS_VALID(destDuration)) {
        fprintf(stderr, "\tDestination movie duration      : %.2f sec\n", CMTimeGetSeconds(destDuration));
    }
    fprintf(stderr, "\n");

bail:
    if(compressionSession)
        CFRelease(compressionSession);
    if(videoSource)
        [videoSource close];
    if(videoSink)
        [videoSink close];

    return err;
}
