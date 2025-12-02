/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A Video Toolbox encoder sample app for low-latency video conferencing.
*/

#ifndef VTEncoderForConferencing_h
#define VTEncoderForConferencing_h

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
    BOOL verbose;
    BOOL replace;
} Options;

OSStatus processVideoConferencing(Options *options);

#endif /* VTEncoderForConferencing_h */
