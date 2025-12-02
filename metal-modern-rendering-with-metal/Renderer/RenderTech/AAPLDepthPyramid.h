/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for class which generates a depth pyramid (i.e. depth mipmaps) from a depth texture.
*/

#import <Metal/Metal.h>
#import <Foundation/Foundation.h>

@interface AAPLDepthPyramid : NSObject

// Initializes this helper, pre-allocating objects from the device.
- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                               library:(nonnull id<MTLLibrary>)library;

// Generates the depth pyramid texture from the specified depth texture.
//  Supports both being the same texture.
- (void)generate:(nonnull id<MTLTexture>)pyramidTexture
    depthTexture:(nonnull id<MTLTexture>)depthTexture
       onEncoder:(nonnull id<MTLComputeCommandEncoder>)encoder;

// Checks if the specified pyramid texture is valid for the depth texture.
//  If not, it should be allocated with allocatePyramidTextureFromDepth.
+ (bool)isPyramidTextureValidForDepth:(_Nullable id<MTLTexture>)pyramidTexture
                          depthTexture:(nonnull id<MTLTexture>)depthTexture;

// Allocates a pyramid texture based on the depth texture it will downsample.
+ (nonnull id<MTLTexture>)allocatePyramidTextureFromDepth:(nonnull id<MTLTexture>)depthTexture
                                                    device:(nonnull id<MTLDevice>)device;

@end
