/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents a video sink that encapsulates an asset writer
        and writes compressed video frames to an output movie file.
*/

#ifndef VideoSink_h
#define VideoSink_h

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A type that receives compressed frames and creates a destination movie file.
@interface VideoSink : NSObject

/// Creates a video sink or returns `nil` if it fails.
/// - Parameters:
///   - sinkFilePath: The destination movie file path.
///   - sinkFileType: The destination movie file type.
///   - codec: The codec type that the system uses to compress the video frames.
///   - width: The video width.
///   - height: The video height.
///   - isRealTime: A Boolean value that indicates whether the video sink tailors its processing for real-time sources.
///                 Set to `true` if video source operates in real time, like a live camera.
///                 Set to `false` for offline transcoding, which may be faster or slower than real time.
+ (nullable instancetype) videoSinkWithFile:(const char *)sinkFilePath
                                   fileType:(AVFileType)sinkFileType
                                  codecType:(CMVideoCodecType)codec
                                 videoWidth:(int32_t)width
                                videoHeight:(int32_t)height
                                   realTime:(BOOL)isRealTime;

/// Appends a video frame to the destination movie file.
/// - Parameter sbuf: A video frame in a `CMSampleBuffer`.
- (void) sendSampleBuffer:(CMSampleBufferRef)sbuf;

/// Closes the destination movie file.
- (void) close;

@end

NS_ASSUME_NONNULL_END

#endif /* VideoSink_h */
