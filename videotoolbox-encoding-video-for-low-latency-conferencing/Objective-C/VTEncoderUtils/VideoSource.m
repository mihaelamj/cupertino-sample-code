/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents a video source that encapsulates an asset reader
        and reads uncompressed video frames from an input movie file.
*/

#import "VideoSource.h"

extern NSURL *createURLFromArgumentCString(const char *argCString);

static const int maxFramesInQueue = 3;


@implementation VideoSource {
@protected
    AVAssetReader *assetReader;
    AVAssetReaderTrackOutput *assetReaderTrackOutput;
    volatile BOOL stopRunning;
}

/// The nominal video frame rate of the source movie file.
@synthesize frameRate;

/// The video width of the source movie file.
@synthesize width;

/// The video height of the source movie file.
@synthesize height;

/// Creates an instance of `VideoSource`.
/// - Parameters:
///   - sourceFilePath: The source movie file path.
///   - pixelFormat: The pixel format of the uncompressed output frames that `VideoSource` delivers.
///   - alwaysCopiesSampleData: A Boolean value that specifies whether to modify the output sample data.
///                             Set to `false` to not modify the output sample data; otherwise, set to `true`.
+ (instancetype) videoSourceWithFile:(const char *)sourceFilePath
                   outputPixelFormat:(uint32_t)pixelFormat
              alwaysCopiesSampleData:(BOOL)alwaysCopiesSampleData;
{
    return [[[self class] alloc] initWithFile:sourceFilePath
                            outputPixelFormat:pixelFormat
                       alwaysCopiesSampleData:alwaysCopiesSampleData];
}

/// Creates an instance of `VideoSource`.
/// - Parameters:
///   - sourceFilePath: The source movie file path.
///   - pixelFormat: The pixel format of the uncompressed output frames that `VideoSource` delivers.
///   - alwaysCopiesSampleData: A Boolean value that specifies whether to modify the output sample data.
///                             Set to `false` to not modify the output sample data; otherwise, set to `true`.
- (instancetype) initWithFile:(const char *)sourceFilePath
            outputPixelFormat:(uint32_t)pixelFormat
       alwaysCopiesSampleData:(BOOL)alwaysCopiesSampleData;
{
    NSError *error = nil;
    OSStatus err = noErr;
    NSURL *sourceURL = nil;
    AVAsset *sourceMovieAsset = nil;
    __block NSArray *sourceMovieVideoTracks = nil;
    AVAssetTrack *videoTrack = nil;
    NSMutableDictionary *pixelBufferAttributes = nil;

    self = [super init];
    if(! self)
        goto bail;

    if(! sourceFilePath) {
        err = -1;
        goto bail;
    }

    sourceURL = createURLFromArgumentCString(sourceFilePath);
    if(! sourceURL) {
        err = -1;
        NSLog(@"VideoSource: invalid sourceURL [%@]", sourceURL);
        goto bail;
    }

    stopRunning = false;

    sourceMovieAsset = [AVAsset assetWithURL:sourceURL];
    if(sourceMovieAsset == nil) {
        err = -108;
        goto bail;
    }

    {
        dispatch_semaphore_t loadSemaphore = dispatch_semaphore_create(0);
        [sourceMovieAsset loadTracksWithMediaType: AVMediaTypeVideo completionHandler: ^(NSArray<AVAssetTrack *> *tracks, NSError *error) {
            sourceMovieVideoTracks = tracks;
            if (error != nil) {
                NSLog(@"AssetVideoReader initialization failed - error loading video tracks: %@", error);
                sourceMovieVideoTracks = nil;
            }
            dispatch_semaphore_signal(loadSemaphore);
        }];
        dispatch_semaphore_wait(loadSemaphore, dispatch_time(DISPATCH_TIME_NOW, 5*NSEC_PER_SEC));
        loadSemaphore = nil;
    }
    if(sourceMovieVideoTracks == nil || ![sourceMovieVideoTracks count]) {
        err = -108;
        NSLog(@"VideoSource: no video track found");
        goto bail;
    }

    videoTrack = [sourceMovieVideoTracks objectAtIndex:0];
    assetReader = [AVAssetReader assetReaderWithAsset:sourceMovieAsset error:&error];
    if(! assetReader) {
        NSLog(@"VideoSource: cannot open asset reader (%@)", error);
        err = -108;
        goto bail;
    }

    frameRate = videoTrack.nominalFrameRate;
    width = (int32_t) videoTrack.naturalSize.width;
    height = (int32_t) videoTrack.naturalSize.height;

    pixelBufferAttributes = [NSMutableDictionary
                             dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:pixelFormat], kCVPixelBufferPixelFormatTypeKey, nil];

    assetReaderTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack
                                                                        outputSettings:pixelBufferAttributes];
    [assetReaderTrackOutput setAlwaysCopiesSampleData:alwaysCopiesSampleData];
    [assetReader addOutput:assetReaderTrackOutput];

    if(! [assetReader startReading]) {
        NSLog(@"VideoSource: cannot start asset reading (%@)", [assetReader error]);
        err = -108;
        goto bail;
    }

bail:
    if (err) {
        self = nil;
    }
    return self;
}

/// Delivers an uncompressed frame to the client.
/// - Parameters:
///   - sbuf: A sample buffer that contains an uncompressed frame.
///   - frameCallback: The callback in which to deliver frames.
- (void) deliverImageBuffer:(CMSampleBufferRef)sbuf frameCallback:(FrameCallbackType)frameCallback
{
    CVImageBufferRef imageBuffer;
    CMTime pts;

    imageBuffer = CMSampleBufferGetImageBuffer(sbuf);
    pts = CMSampleBufferGetPresentationTimeStamp(sbuf);
    CVPixelBufferRetain(imageBuffer);
    CFRelease(sbuf);

    if(imageBuffer) {
        frameCallback(imageBuffer, pts);
    } else {
        NSLog(@"VideoSource: no image buffer");
    }
}

/// Reads next video frame from the source movie file.
- (CMSampleBufferRef) getNextSampleBuffer
{
    return [assetReaderTrackOutput copyNextSampleBuffer];
}

/// Delivers video frames in a callback, up to the frame count that you specify.
///
/// This method delivers `CVImageBuffer` objects via `frameCallback`. It delivers all video frames of the input movie file when `frameCount`
/// is `0`, and up to `frameCount` frames when it's greater than `0`. It blocks until `frameCallback` for the last video frame returns.
///
/// - Parameters:
///   - frameCount: The number of frames to deliver.
///   - frameCallback: The callback in which to deliver frames.
- (OSStatus) run:(uint64_t)frameCount frameCallback:(FrameCallbackType)frameCallback
{
    OSStatus err = noErr;
    uint64_t frameNumber = 0;
    uint64_t framesToDeliver = frameCount;

    if(! frameCallback) {
        err = -100;
        goto bail;
    }

    if(! framesToDeliver)
        framesToDeliver = (uint64_t)(-1);

    while((! stopRunning) && (frameNumber < framesToDeliver) && ([assetReader status] == AVAssetReaderStatusReading)) {
        CMSampleBufferRef sbuf = [self getNextSampleBuffer];

        if(sbuf) {
            frameNumber++;
            [self deliverImageBuffer:sbuf frameCallback:frameCallback];
        }
        else {
            break;
        }
    }

bail:
    return err;
}

/// Closes the source movie file.
- (void) close
{
}

@end

/// A type that reads video frames from a source movie file and delivers uncompressed frames one-by-one in real time in the specified pixel format.
@implementation RealTimeVideoSource {
@private
    CFMutableArrayRef array;
    dispatch_semaphore_t semaphore;
    dispatch_queue_t deliveryQueue;
    dispatch_group_t deliveryGroup;
    dispatch_source_t timebaseTimer;
    CMTimebaseRef timebase;
}

/// Creates an instance of `RealTimeVideoSource`.
/// - Parameters:
///   - sourceFilePath: The source movie file path.
///   - pixelFormat: The pixel format of the uncompressed output frames that `VideoSource` delivers.
///   - alwaysCopiesSampleData: A Boolean value that specifies whether to modify the output sample data.
///                             Set to `false` to not modify the output sample data; otherwise, set to `true`.
- (instancetype) initWithFile:(const char *)sourceFilePath
            outputPixelFormat:(uint32_t)pixelFormat
       alwaysCopiesSampleData:(BOOL)alwaysCopiesSampleData;
{
    OSStatus err = noErr;

    self = [super initWithFile:sourceFilePath outputPixelFormat:pixelFormat alwaysCopiesSampleData:alwaysCopiesSampleData];
    if(! self)
        goto bail;

    array = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    semaphore = dispatch_semaphore_create(maxFramesInQueue);

    deliveryQueue = dispatch_queue_create("Delivery queue", DISPATCH_QUEUE_SERIAL);
    deliveryGroup = dispatch_group_create();
    timebaseTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, deliveryQueue);

    CMTimebaseCreateWithSourceClock(kCFAllocatorDefault, CMClockGetHostTimeClock(), &timebase);
    CMTimebaseSetTime(timebase, kCMTimeZero);
    CMTimebaseSetRate(timebase, 0.0);

bail:
    if (err) {
        self = nil;
    }
    return self;
}

- (void) dealloc
{
    if(array)
        CFRelease(array);
    if(timebase)
        CFRelease(timebase);
}

/// Number of frames in the frame queue.
- (long) size {
    return CFArrayGetCount(array);
}

/// `true` if the frame queue is full; otherwise, `false`.
- (BOOL) isFull {
    return (self.size == (long) maxFramesInQueue);
}

/// Enqueues a frame to the frame queue.
/// - Parameter sbuf: A sample buffer that contains a video frame.
- (void) enqueue:(CMSampleBufferRef)sbuf
{
    CFArrayAppendValue(array, sbuf);
}

/// Returns the oldest frame from the frame queue or `NULL` if the frame queue is empty.
- (CMSampleBufferRef) dequeue
{
    CMSampleBufferRef sbuf = NULL;

    if(self.size > 0) {
        sbuf = (CMSampleBufferRef) CFArrayGetValueAtIndex(array, 0);
        CFArrayRemoveValueAtIndex(array, 0);
    }

    return sbuf;
}

/// The presentation time stamp of the oldest frame in the frame queue.
- (CMTime) headPTS
{
    CMTime pts = kCMTimeInvalid;

    if(self.size > 0) {
        CMSampleBufferRef sbuf = (CMSampleBufferRef) CFArrayGetValueAtIndex(array, 0);
        pts = CMSampleBufferGetPresentationTimeStamp(sbuf);
    }

    return pts;
}

/// Delivers the oldest frame from the frame queue and schedules the delivery of the next frame if the frame queue isn't empty.
/// - Parameter frameCallback: The callback in which to deliver frames.
- (void) scheduleSampleBufferDelivery:(FrameCallbackType)frameCallback
{
    CMSampleBufferRef sbuf = [self dequeue];

    if(sbuf) {
        dispatch_semaphore_signal(semaphore);

        [self deliverImageBuffer:sbuf frameCallback:frameCallback];
        dispatch_group_leave(deliveryGroup);

        if(self.size > 0) {
            CMTimebaseSetTimerDispatchSourceNextFireTime(timebase, timebaseTimer, self.headPTS, 0);
        }
    }
}

/// Delivers video frames in a callback, up to the frame count that you specify.
///
/// This method delivers `CVImageBuffer` objects via `frameCallback`. It delivers all video frames of the input movie file when `frameCount`
/// is `0`, and up to `frameCount` frames when it's greater than `0`. It blocks until `frameCallback` for the last video frame returns.
///
/// - Parameters:
///   - frameCount: The number of frames to deliver.
///   - frameCallback: The callback in which to deliver frames.
- (OSStatus) run:(uint64_t)frameCount frameCallback:(FrameCallbackType)frameCallback
{
    OSStatus err = noErr;
    uint64_t frameNumber = 0;
    uint64_t framesToDeliver = frameCount;

    if(! frameCallback) {
        err = -100;
        goto bail;
    }

    if(! framesToDeliver) {
        framesToDeliver = (uint64_t)(-1);
    }

    {
        dispatch_source_set_event_handler(timebaseTimer, ^{
            [self scheduleSampleBufferDelivery:frameCallback];
        });
    }
    dispatch_activate(timebaseTimer);
    CMTimebaseAddTimerDispatchSource(timebase, timebaseTimer);

    while((! stopRunning) && (frameNumber < framesToDeliver) && ([assetReader status] == AVAssetReaderStatusReading)) {
        CMSampleBufferRef sbuf = [self getNextSampleBuffer];

        if(sbuf) {
            frameNumber++;
            dispatch_group_enter(deliveryGroup);

            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

            dispatch_sync(deliveryQueue, ^{
                [self enqueue:sbuf];

                if((CMTimebaseGetRate(timebase) != 1.0) && self.isFull) {
                    CMTime nextPTS = self.headPTS;
                    if (CMTIME_IS_VALID(nextPTS)) {
                        CMTimebaseSetTimerDispatchSourceNextFireTime(timebase, timebaseTimer, nextPTS, 0);
                        CMTimebaseSetTime(timebase, nextPTS);
                        CMTimebaseSetRate(timebase, 1.0);
                    }
                }
            });
        }
        else {
            break;
        }
    }

    {
        dispatch_sync(deliveryQueue, ^{
            if((CMTimebaseGetRate(timebase) != 1.0) && (self.size > 0)) {
                CMTime nextPTS = self.headPTS;
                if (CMTIME_IS_VALID(nextPTS)) {
                    CMTimebaseSetTimerDispatchSourceNextFireTime(timebase, timebaseTimer, nextPTS, 0);
                    CMTimebaseSetTime(timebase, nextPTS);
                    CMTimebaseSetRate(timebase, 1.0);
                }
            }
        });
    }

    dispatch_group_wait(deliveryGroup, DISPATCH_TIME_FOREVER);

bail:
    return err;
}

/// Closes the source movie file.
- (void) close
{
    dispatch_activate(timebaseTimer);
}

@end
