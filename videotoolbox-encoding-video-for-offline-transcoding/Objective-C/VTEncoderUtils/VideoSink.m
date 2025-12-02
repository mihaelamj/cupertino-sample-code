/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents a video sink that encapsulates an asset writer
        and writes compressed video frames to an output movie file.
*/

#import "VideoSink.h"

extern NSURL *createURLFromArgumentCString(const char *argCString);

/// A type that receives compressed frames and creates a destination movie file.
@implementation VideoSink {
@private
    AVAssetWriter *assetWriter;
    AVAssetWriterInput *assetWriterInput;
    dispatch_semaphore_t semaphore;
    BOOL sessionStarted;
}

/// Creates a video sink or returns `nil` if it fails.
/// - Parameters:
///   - sinkFilePath: The destination movie file path.
///   - sinkFileType: The destination movie file type.
///   - codec: The codec type that the system uses to compress the video frames.
///   - width: The video width.
///   - height: The video height.
///   - isRealTime: A Boolean value that indicates whether the video sink tailors its processing for real time sources.
///                 Set to `true` if video source operates in real time, like a live camera.
///                 Set to `false` for offline transcoding, which may be faster or slower than real time.
+ (instancetype) videoSinkWithFile:(const char *)sinkFilePath
                          fileType:(AVFileType)sinkFileType
                         codecType:(CMVideoCodecType)codec
                        videoWidth:(int32_t)width
                       videoHeight:(int32_t)height
                          realTime:(BOOL)isRealTime
{
    return [[[self class] alloc] initWithFile:sinkFilePath
                                     fileType:sinkFileType
                                    codecType:codec
                                   videoWidth:width
                                  videoHeight:height
                                     realTime:isRealTime];
}
/// Creates a video sink or returns `nil` if it fails.
/// - Parameters:
///   - sinkFilePath: The destination movie file path.
///   - sinkFileType: The destination movie file type.
///   - codec: The codec type that the system uses to compress the video frames.
///   - width: The video width.
///   - height: The video height.
///   - isRealTime: A Boolean value that indicates whether the video sink tailors its processing for real time sources.
///                 Set to `true` if video source operates in real time, like a live camera.
///                 Set to `false` for offline transcoding, which may be faster or slower than real time.
- (instancetype) initWithFile:(const char *)sinkFilePath
                     fileType:(AVFileType)sinkFileType
                    codecType:(CMVideoCodecType)codec
                   videoWidth:(int32_t)width
                  videoHeight:(int32_t)height
                     realTime:(BOOL)isRealTime
{
    NSError *error = nil;
    OSStatus err = noErr;
    NSURL *sinkURL = nil;
    CMFormatDescriptionRef videoFormatDesc = nil;

    self = [super init];
    if(! self)
        goto bail;

    if(! sinkFilePath) {
        err = -1;
        goto bail;
    }

    sinkURL = createURLFromArgumentCString(sinkFilePath);
    if(! sinkURL) {
        err = -1;
        NSLog(@"VideoSink: invalid sinkURL [%@]", sinkURL);
        goto bail;
    }

    semaphore = dispatch_semaphore_create(0);
    sessionStarted = false;

    assetWriter = [AVAssetWriter assetWriterWithURL:sinkURL fileType:sinkFileType error:&error];
    if(! assetWriter) {
        err = -1;
        NSLog(@"VideoSink: assetWriterWithURL failed for URL %@ — [%@]", sinkURL, error);
        goto bail;
    }

    err = CMVideoFormatDescriptionCreate(kCFAllocatorDefault, codec, width, height, NULL, &videoFormatDesc);
    if(err) {
        err = -1;
        NSLog(@"VideoSink: CMVideoFormatDescriptionCreate failed — [%d]", err);
        goto bail;
    }

    assetWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                      outputSettings:nil
                                                    sourceFormatHint:videoFormatDesc];
    if(! assetWriterInput) {
        err = -1;
        NSLog(@"VideoSink: AVAssetWriterInput initWithMediaType failed.");
        goto bail;
    }
    if(isRealTime) {
        assetWriterInput.expectsMediaDataInRealTime = true;
    }

    [assetWriter addInput:assetWriterInput];
    if(! [assetWriter startWriting]) {
        err = -1;
        NSLog(@"VideoSink: AVAssetWriter startWriting failed.");
        goto bail;
    }

bail:
    if(videoFormatDesc) {
        CFRelease(videoFormatDesc);
    }
    if(err) {
        self = nil;
    }
    return self;
}

/// Appends a video frame to the destination movie file.
/// - Parameter sbuf: A video frame in a `CMSampleBuffer`.
- (void) sendSampleBuffer:(CMSampleBufferRef)sbuf
{
    if(! sessionStarted) {
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sbuf);
        [assetWriter startSessionAtSourceTime:pts];
        sessionStarted = true;
    }
    
    if(assetWriterInput.isReadyForMoreMediaData) {
        [assetWriterInput appendSampleBuffer:sbuf];
    }
    else {
        // Dropping a compressed frame results in a corrupted video in real
        // life. Drop all subsequent compressed frames until the system
        // generates a new IDR frame if the app is latency-sensitive, such as
        // for conferencing. Block the encoding pipeline until the output is
        // unblocked if the app isn't latency-sensitive, such as for
        // transcoding. This sample app doesn't include this implementation.
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sbuf);
        NSLog(@"VideoSink: dropped a frame [PTS: %.3f]", CMTimeGetSeconds(pts));
    }
}

/// Closes the destination movie file.
- (void) close
{
    [assetWriterInput markAsFinished];
    [assetWriter finishWritingWithCompletionHandler:^{
        dispatch_semaphore_signal(self->semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    if(assetWriter.status == AVAssetWriterStatusFailed) {
        NSLog(@"VideoSink: close failed.");
    }
}

@end
