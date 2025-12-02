/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the renderer class.
*/

@import MetalKit;
#import "AAPLShaderTypes.h"

@interface AAPLRenderer : NSObject

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;

- (void)drawInMTKView:(nonnull MTKView *)view;

- (void)drawableSizeWillChange:(CGSize)size;

@property (nonatomic, readonly) size_t  numVisibleFragments;
@property (nonatomic, readonly) size_t  numSpheresDrawn;
@property (nonatomic)           float   position;
@property (nonatomic)           AAPLVisibilityTestingMode visibilityTestingMode;

@end
