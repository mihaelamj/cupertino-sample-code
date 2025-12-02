/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for the capture manager class that invokes a GPU trace.
*/

@import MetalKit;

@interface AAPLCaptureManager : NSObject

typedef void (^CaptureCompletionHandler)(BOOL success, NSError* _Nullable error);

- (void)setupCaptureInXcode:(nonnull MTKView *)view;
- (void)setupCaptureToFile:(nonnull MTKView *)view;

- (void)captureWithDescriptor:(nonnull MTLCaptureDescriptor *)descriptor
            completionHandler:(nullable CaptureCompletionHandler)completionHandler;

- (void)startCapture;
- (void)stopCapture;

@property (readwrite, nonatomic) MTLCaptureDescriptor* _Nullable captureDescriptor;

@end

