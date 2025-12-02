/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utility functions that assist in video processing and movie file handling.
*/

#import "VTEncoderUtil.h"
#include <string.h>
#import <VideoToolbox/VTCompressionSession.h>

/// Creates an NSURL instance from the file path.
/// - Parameter argCString: A C string for file path.
NSURL *createURLFromArgumentCString(const char *argCString)
{
    if(! argCString)
        return nil;

    NSString *fileString = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:argCString length:strlen(argCString)];
    if(! strstr(argCString, "://")) {
        return [NSURL fileURLWithPath:fileString];
    }
    return [NSURL URLWithString:fileString];
}

/// Returns a pointer to the application name after directory names in the full path.
/// - Parameter path: A string for the full path.
const char *getApplicationName(const char *path)
{
    const char *name;

    if(! path)
        return NULL;

    name = strrchr(path, '/');
    if(name) {
        name++;
    }
    else {
        name = path;
    }

    return name;
}

/// Converts an integer code to a string.
/// - Parameter value: An integer that represents a four-character code.
/// - Returns: A human-readable four-character code in a string.
const char *fourCCToString(uint32_t value)
{
    static uint32_t storage[2] = {0};

    storage[0] = EndianU32_NtoB(value);

    return (char *) storage;
}

/// Validates if this app supports the provided video codec type.
/// - Parameter codec: The video codec type to use for video encoding.
OSStatus validateCodecType(CMVideoCodecType codec)
{
    OSStatus err = noErr;

    if(codec != kCMVideoCodecType_H264 && codec != kCMVideoCodecType_HEVC) {
        err = -1;
    }
    return err;
}

/// Validates if this app supports the provided pixel format.
/// - Parameter pixelFormat: The pixel format to use for uncompressed frame input to encoder.
OSStatus validatePixelFormat(FourCharCode pixelFormat)
{
    OSStatus err = noErr;

    if(pixelFormat != kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange && pixelFormat != kCVPixelFormatType_32BGRA) {
        err = -1;
    }
    return err;
}

/// Creates a new movie file name if this app doesn't support the provided movie file name extension and returns the file type.
/// - Parameters:
///   - moviePath: A string for original movie file path that the person specified.
///   - newPathOut: A pointer to new movie file path string to use in place of the original movie path. If this string is `NULL`, continue
///                 to use the original movie file path. If this string isn't `NULL`, it is client's responsibility to free the string.
AVFileType createNewMoviePathIfNecessaryAndGetFileType(const char *moviePath, const char **newPathOut)
{
    AVFileType fileType = nil;
    const char *extension = strrchr(moviePath, '.');

    if(extension) {
        if(0 == strcasecmp(extension, ".mov") || 0 == strcasecmp(extension, ".qt")) {
            fileType = AVFileTypeQuickTimeMovie;
        }
        else if(0 == strcasecmp(extension, ".m4v")) {
            fileType = AVFileTypeAppleM4V;
        }
        else if(0 == strcasecmp(extension, ".mp4")) {
            fileType = AVFileTypeMPEG4;
        }
    }

    if(newPathOut) {
        *newPathOut = NULL;
    }

    if(! fileType) {
        // Suggest `AVFileTypeQuickTimeMovie` even if `newPathOut` is `NULL`.
        fileType = AVFileTypeQuickTimeMovie;

        if(newPathOut) {
            char *pathBuf = NULL;
            const size_t extraSpace = 5;
            size_t sourceLen = strlen(moviePath);
            size_t bufferLen = sourceLen + extraSpace;
            
            pathBuf = (char *) calloc(1, bufferLen);
            strlcpy(pathBuf, moviePath, bufferLen);
            strlcpy(&pathBuf[ sourceLen ], ".mov", extraSpace);

            *newPathOut = pathBuf;
        }
    }

    return fileType;
}

/// Parse input string as encode preset constant. Returns `noErr` on success.
/// - Parameters:
///   - preset: String representing encode preset.
///   - outPreset: Output encode preset constant.
OSStatus parsePreset(const char *preset, CFStringRef *outPreset)
{
    OSStatus err = noErr;

    if(0 == strcmp("videoConferencing", preset)) {
        *outPreset = kVTCompressionPreset_VideoConferencing;
    }
    else {
        err = -1;
    }

    return err;
}

/// Convert encode preset constant to string.
/// - Parameters:
///   - preset: Encode preset constant.
const char *presetToString(CFStringRef preset)
{
    if(kVTCompressionPreset_VideoConferencing == preset)
        return "videoConferencing";
    else
        return "unknown";
}

/// Parse input string as codec profile level constant. Returns `noErr` on success.
/// - Parameters:
///   - preset: String representing codec profile.
///   - outPreset: Output codec profile level constant.
OSStatus parseProfile(const char *profile, CMVideoCodecType codec, CFStringRef *outProfile)
{
    OSStatus err = noErr;

    if(kCMVideoCodecType_H264 == codec) {
        if(0 == strcmp("main", profile)) {
            *outProfile = kVTProfileLevel_H264_Main_AutoLevel;
        }
        else if(0 == strcmp("high", profile)) {
            *outProfile = kVTProfileLevel_H264_High_AutoLevel;
        }
        else {
            err = -1;
        }
    }
    else if(kCMVideoCodecType_HEVC == codec) {
        if(0 == strcmp("main", profile)) {
            *outProfile = kVTProfileLevel_HEVC_Main_AutoLevel;
        }
        else if(0 == strcmp("main10", profile)) {
            *outProfile = kVTProfileLevel_HEVC_Main10_AutoLevel;
        }
        else {
            err = -1;
        }
    }
    else {
        err = -1;
    }

    return err;
}

/// Convert codec profile level constant to string.
/// - Parameters:
///   - profile: The codec profile level constant.
const char *profileToString(CFStringRef profile)
{
    if(kVTProfileLevel_H264_Main_AutoLevel == profile || kVTProfileLevel_HEVC_Main_AutoLevel == profile)
        return "main";
    else if(kVTProfileLevel_H264_High_AutoLevel == profile)
        return "high";
    else if(kVTProfileLevel_HEVC_Main10_AutoLevel == profile)
        return "main10";
    else
        return "unknown";
}
