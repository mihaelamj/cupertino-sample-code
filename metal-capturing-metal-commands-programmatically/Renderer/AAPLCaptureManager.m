/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the capture manager class that invokes a GPU trace.
*/

#import "AAPLCaptureManager.h"

@implementation AAPLCaptureManager
{
    CaptureCompletionHandler _captureCompletionHandler;
}

-(nonnull instancetype)init
{
    self = [super init];

    return self;
}

#pragma mark - Capture Destination Methods

- (void)setupCaptureInXcode:(nonnull MTKView *)view
{
    MTLCaptureDescriptor *descriptor = [[MTLCaptureDescriptor alloc] init];
    descriptor.destination = MTLCaptureDestinationDeveloperTools;
    descriptor.captureObject = ((MTKView *)view).device;

    // You don't need to add a completion handler.
    // Xcode automatically pauses your app's execution when you complete the capture.
    [self captureWithDescriptor:descriptor completionHandler:nil];
}

- (void)setupCaptureToFile:(nonnull MTKView *)view
{
    // Use the `.gputrace` extension for your GPU trace capture files.
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.nameFieldStringValue = @"My_Trace.gputrace";

    [savePanel beginSheetModalForWindow:view.window completionHandler:^(NSModalResponse result)
      {
        if (result == NSModalResponseOK) {
            NSURL *URL = savePanel.URL;
            NSLog(@"%@", URL);

            MTLCaptureDescriptor *descriptor = [[MTLCaptureDescriptor alloc] init];
            descriptor.destination = MTLCaptureDestinationGPUTraceDocument;
            descriptor.outputURL = URL;
            descriptor.captureObject = ((MTKView *)view).device;

            // Set up a completion handler to be called in the next rendered frame.
            [self captureWithDescriptor:descriptor completionHandler:^(BOOL success, NSError *error)
              {
                if (success) {
                    [NSWorkspace.sharedWorkspace activateFileViewerSelectingURLs:@[ URL ]];
                } else {
                    NSAlert *alert = [NSAlert alertWithError:error];
                    [alert beginSheetModalForWindow:view.window completionHandler:nil];
                }
              }];
        }
      }];
}

- (void)captureWithDescriptor:(MTLCaptureDescriptor *)descriptor
            completionHandler:(CaptureCompletionHandler)completionHandler
{
    _captureDescriptor = descriptor;
    _captureCompletionHandler = [completionHandler copy];
}

#pragma mark - Capture Logic Methods

// Start the capture.
- (void)startCapture
{
    NSError *error = nil;
    BOOL success = [MTLCaptureManager.sharedCaptureManager startCaptureWithDescriptor:_captureDescriptor
                                                                                error:&error];

    if (!success) {
        if (_captureCompletionHandler != nil) {
            // Issue a callback to the completion handler and handle the error.
            _captureCompletionHandler(NO, error);
        }
        
        // Disable the current capture code.
        _captureDescriptor = nil;
        _captureCompletionHandler = nil;
    }
}

// Stop the capture.
- (void)stopCapture
{
    [MTLCaptureManager.sharedCaptureManager stopCapture];

    if (_captureCompletionHandler != nil) {
        // Issue a callback to the completion handler.
        _captureCompletionHandler(YES, nil);
    }

    // Disable the current capture code.
    _captureDescriptor = nil;
    _captureCompletionHandler = nil;
}

@end

