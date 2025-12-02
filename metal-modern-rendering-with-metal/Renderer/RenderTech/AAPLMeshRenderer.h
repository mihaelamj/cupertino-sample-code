/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for class which renders a meshes
*/

#import "AAPLRenderPasses.h"
#import "AAPLConfig.h"

#import <Metal/Metal.h>

@class AAPLMesh;
@class AAPLTextureManager;

struct AAPLICBData;
struct AAPLCameraParams;

// Encapsulates the pipeline states and intermediate objects for rendering meshes.
@interface AAPLMeshRenderer : NSObject

// Initializes this object, allocating metal objects from the device based on
//  functions in the library.
-(nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                       textureManager:(nonnull AAPLTextureManager*)textureManager
                         materialSize:(size_t)materialSize
                  alignedMaterialSize:(size_t)alignedMaterialSize
                              library:(nonnull id<MTLLibrary>)library
                  GBufferPixelFormats:(nonnull const MTLPixelFormat*)GBufferPixelFormats
                  lightingPixelFormat:(MTLPixelFormat)lightingPixelFormat
                   depthStencilFormat:(MTLPixelFormat)depthStencilFormat
                          sampleCount:(NSUInteger)sampleCount
                 useRasterizationRate:(BOOL)useRasterizationRate
           singlePassDeferredLighting:(BOOL)singlePassDeferredLighting
                 lightCullingTileSize:(uint)lightCullingTileSize
              lightClusteringTileSize:(uint)lightClusteringTileSize
           useSinglePassCSMGeneration:(BOOL)useSinglePassCSMGeneration
       genCSMUsingVertexAmplification:(BOOL)genCSMUsingVertexAmplification;


-(void)rebuildPipelinesWithLibrary:(nonnull id<MTLLibrary>)library
               GBufferPixelFormats:(nonnull const MTLPixelFormat*)GBufferPixelFormats
               lightingPixelFormat:(MTLPixelFormat)lightingPixelFormat
                depthStencilFormat:(MTLPixelFormat)depthStencilFormat
                       sampleCount:(NSUInteger)sampleCount
              useRasterizationRate:(BOOL)useRasterizationRate
        singlePassDeferredLighting:(BOOL)singlePassDeferredLighting
        useSinglePassCSMGeneration:(BOOL)useSinglePassCSMGeneration
    genCSMUsingVertexAmplification:(BOOL)genCSMUsingVertexAmplification;

// Writes commands prior to executing a set of passes for rendering a mesh.
- (void)prerender:(nonnull AAPLMesh*)mesh
           passes:(nonnull NSArray*)passes
           direct:(BOOL)direct
          icbData:(AAPLICBData&)icbData
            flags:(nullable NSDictionary*)flags
        onEncoder:(nonnull id<MTLRenderCommandEncoder>)encoder;

// Writes commands to render meshes using the command buffer.
- (void)render:(nonnull AAPLMesh*)mesh
          pass:(AAPLRenderPass)pass
        direct:(BOOL)direct
       icbData:(AAPLICBData&)icbData
         flags:(nullable NSDictionary*)flags
  cameraParams:(AAPLCameraParams&)cameraParams
     onEncoder:(nonnull id<MTLRenderCommandEncoder>)encoder;

@end
