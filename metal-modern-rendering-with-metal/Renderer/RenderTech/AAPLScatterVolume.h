/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for class which manages state to render a scatter volume
*/

#import "AAPLConfig.h"
#import <MetalKit/MetalKit.h>

#if USE_SCATTERING_VOLUME

// Encapsulates the pipeline states and intermediate objects for generating a
//  volume of scattered lighting information.
@interface AAPLScatterVolume : NSObject

// The resulting volume data from the last update.
@property (nonatomic, readonly) id<MTLTexture> _Nonnull scatteringAccumVolume;

// User specified noise texture for updates.
@property id<MTLTexture> _Nullable noiseTexture;
@property id<MTLTexture> _Nullable perlinNoiseTexture;

// Initializes this object, allocating metal objects from the device based on
//  functions in the library.
- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                               library:(nonnull id<MTLLibrary>)library
                  useRasterizationRate:(BOOL)useRasterizationRate
                  lightCullingTileSize:(uint)lightCullingTileSize
               lightClusteringTileSize:(uint)lightClusteringTileSize;

- (void)rebuildPipelinesWithLibrary:(nonnull id<MTLLibrary>)library
               useRasterizationRate:(BOOL)useRasterizationRate;

// Writes commands to update the volume using the command buffer.
// Applies temporal updates which can be reset with the resetHistory flag.
- (void)        update:(nonnull id<MTLCommandBuffer>)commandBuffer
       frameDataBuffer:(nonnull id<MTLBuffer>)frameDataBuffer
    cameraParamsBuffer:(nonnull id<MTLBuffer>)cameraParamsBuffer
             shadowMap:(nonnull id<MTLTexture>)shadowMap
      pointLightBuffer:(nonnull id<MTLBuffer>)pointLightBuffer
       spotLightBuffer:(nonnull id<MTLBuffer>)spotLightBuffer
     pointLightIndices:(nullable id<MTLBuffer>)pointLightIndices
      spotLightIndices:(nullable id<MTLBuffer>)spotLightIndices
#if USE_SPOT_LIGHT_SHADOWS
      spotLightShadows:(nullable id<MTLTexture>)spotLightShadows
#endif
                rrData:(nullable id<MTLBuffer>)rrMapData
             clustered:(bool)clustered
          resetHistory:(bool)resetHistory;

// Resizes the internal data structures to the required output size.
- (void)resize:(CGSize)size;

@end

#endif
