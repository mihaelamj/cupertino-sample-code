/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the renderer class that performs Metal setup and per-frame rendering.
*/

#import <MetalKit/MetalKit.h>

@interface AAPLRenderer : NSObject

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView*)mtkView;

- (void)mtkView:(nonnull MTKView*) view drawableSizeWillChange:(CGSize)size;

- (void)drawInMTKView:(nonnull MTKView*) view;

/// This property cycles between the detailed objects.
@property (nonatomic) bool cycleDetailedObjects;
/// This property controls (but not currently with the UI) whether the objects are rotating.
@property (nonatomic) bool rotateObjects;
/// The property tells the renderer to reload the currently detailed object.
@property (nonatomic) bool reloadDetailedObject;
/// This property tells the renderer to use MTLIO instead of the traditional `fread` approach.
@property (nonatomic) bool useMTLIO;
/// This property reports the memory usage for the app.
@property (nonatomic, nonnull) NSString* infoString;

@end
