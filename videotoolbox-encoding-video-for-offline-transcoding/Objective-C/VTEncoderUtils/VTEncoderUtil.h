/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utility functions that assist in video processing and movie file handling.
*/

#ifndef VTEncoderUtil_h
#define VTEncoderUtil_h

#import <AVFoundation/AVFoundation.h>

#define checkArgCount(count)                                \
    if(argc < count) {                                      \
        fprintf(stderr, "Error: missing argument.\n");      \
        err = -1;                                           \
        goto bail;                                          \
    }

/// Returns a pointer to the application name after directory names in the full path.
/// - Parameter path: A string for the full path.
const char *getApplicationName(const char *path);

/// Converts an integer code to a string.
/// - Parameter value: An integer that represents a four-character code.
/// - Returns: A human-readable four-character code in a string.
const char *fourCCToString(uint32_t value);

/// Validates if this app supports the provided video codec type.
/// - Parameter codec: The video codec type to use for video encoding.
OSStatus validateCodecType(CMVideoCodecType codec);

/// Validates if this app supports the provided pixel format.
/// - Parameter pixelFormat: The pixel format to use for uncompressed frame input to the encoder.
OSStatus validatePixelFormat(FourCharCode pixelFormat);

/// Creates a new movie file name if this app doesn't support the provided movie file name extension and returns the file type.
/// - Parameters:
///   - moviePath: A string for original movie file path that the person specified.
///   - newPathOut: A pointer to new movie file path string to use in place of the original movie path. If this string is `NULL`, continue
///                 to use the original movie file path. If this string isn't `NULL`, it is client's responsibility to free the string.
AVFileType createNewMoviePathIfNecessaryAndGetFileType(const char *moviePath, const char **newPathOut);

/// Parse input string as QP Modulation Level constant. Returns `noErr` on success.
/// - Parameters:
///	  - level: String representing QP Modulation Level.
///	  - outLevel: Output QP Modulation level constant.
OSStatus parseQPModulationLevel(const char *level, int32_t *outLevel);

/// Convert QP Modulation Level constant to string.
/// - Parameters:
///   - level: QP Modulation Level constant.
const char *qpModulationLevelToString(int32_t level);

/// Parse input string as encode preset constant. Returns `noErr` on success.
/// - Parameters:
///   - preset: String representing encode preset.
///   - outPreset: Output encode preset constant.
OSStatus parsePreset(const char *preset, CFStringRef *outPreset);

/// Convert encode preset constant to string.
/// - Parameters:
///   - preset: Encode preset constant.
const char *presetToString(CFStringRef preset);

/// Parse input string as codec profile level constant. Returns `noErr` on success.
/// - Parameters:
///   - preset: String representing codec profile.
///   - outPreset: Output codec profile level constant.
OSStatus parseProfile(const char *profile, CMVideoCodecType codec, CFStringRef *outProfile);

/// Convert codec profile level constant to string.
/// - Parameters:
///   - profile: The codec profile level constant.
const char *profileToString(CFStringRef profile);

#endif /* VTEncoderUtil_h */
