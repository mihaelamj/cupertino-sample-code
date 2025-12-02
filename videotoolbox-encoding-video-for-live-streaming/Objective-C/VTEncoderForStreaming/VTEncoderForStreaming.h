/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A Video Toolbox encoder sample app for live streaming.
*/

#ifndef VTEncoderForStreaming_h
#define VTEncoderForStreaming_h

#import "VTEncoderUtil.h"

typedef struct {
    const char *sourceMoviePath;
    const char *destMoviePath;
    AVFileType destFileType;
    int64_t frameCount;
    FourCharCode pixelFormat;
    CMVideoCodecType codec;
    CFStringRef preset;
    CFStringRef profile;
    int32_t destWidth;
    int32_t destHeight;
    int32_t destBitRate;
    int32_t maxKeyFrameInterval;
    Float64 maxKeyFrameIntervalDuration;
    BOOL lookAheadFramesIsSet;
    int32_t lookAheadFrames;
    BOOL spatialAdaptiveQPIsSet;
    int32_t spatialAdaptiveQP;
    BOOL constantBitRateMode;
    BOOL verbose;
    BOOL replace;
} Options;

OSStatus processVideoStreaming(Options *options);

#endif /* VTEncoderForStreaming_h */
