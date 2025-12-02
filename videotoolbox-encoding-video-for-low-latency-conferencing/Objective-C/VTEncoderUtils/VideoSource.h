/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents a video source that encapsulates an asset reader
        and reads uncompressed video frames from an input movie file.
*/

#ifndef VideoSource_h
#define VideoSource_h

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A type of the callback function that delivers an uncompressed frame.
typedef void (^FrameCallbackType)(CVImageBufferRef imageBuffer, CMTime PTS);

/// A type that reads video frames from a source movie file and delivers uncompressed frames one-by-one in the specified pixel format.
@interface VideoSource : NSObject

/// The nominal video frame rate of the source movie file.
@property(nonatomic, readonly) float frameRate;

/// The video width of the source movie file.
@property(nonatomic, readonly) int32_t width;

/// The video height of the source movie file.
@property(nonatomic, readonly) int32_t height;

/// Creates an instance of `VideoSource`.
/// - Parameters:
///   - sourceFilePath: The source movie file path.
///   - pixelFormat: The pixel format of the uncompressed output frames that `VideoSource` delivers.
///   - alwaysCopiesSampleData: A Boolean value that specifies whether to modify the output sample data.
///                             Set to `false` to not modify the output sample data; otherwise, set to `true`.
+ (nullable instancetype) videoSourceWithFile:(const char *)sourceFilePath
                            outputPixelFormat:(uint32_t)pixelFormat
                       alwaysCopiesSampleData:(BOOL)alwaysCopiesSampleData;

/// Delivers video frames in a callback, up to the frame count that you specify.
///
/// This method delivers `CVImageBuffer` objects via `frameCallback`. It delivers all video frames of the input movie file when `frameCount`
/// is `0`, and up to `frameCount` frames when it's greater than `0`. It blocks until `frameCallback` for the last video frame returns.
///
/// - Parameters:
///   - frameCount: The number of frames to deliver.
///   - frameCallback: The callback in which to deliver frames.
- (OSStatus) run:(uint64_t)frameCount frameCallback:(FrameCallbackType)frameCallback;

/// Closes the source movie file.
- (void) close;

@end


/// A type that reads video frames from a source movie file and delivers uncompressed frames one-by-one in real time in the specified pixel format.
@interface RealTimeVideoSource : VideoSource
@end

NS_ASSUME_NONNULL_END

#endif /* VideoSource_h */
