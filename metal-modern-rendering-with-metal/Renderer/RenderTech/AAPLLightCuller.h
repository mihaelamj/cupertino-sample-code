/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for class which culls light volumes.
*/

#import <Metal/Metal.h>
#import <simd/simd.h>
#import "AAPLConfig.h"

// Stores results from the culling processes.
struct LightCullResult
{
    // Output buffers for light bounds from executeCoarseCulling().
    id <MTLBuffer> _Nonnull pointLightXYCoarseCullIndicesBuffer;
    id <MTLBuffer> _Nonnull spotLightXYCoarseCullIndicesBuffer;

    // Output buffers for light indices from executeCulling().
    id <MTLBuffer> _Nonnull pointLightIndicesBuffer;
    id <MTLBuffer> _Nonnull pointLightIndicesTransparentBuffer;
    id <MTLBuffer> _Nonnull spotLightIndicesBuffer;
    id <MTLBuffer> _Nonnull spotLightIndicesTransparentBuffer;

    id <MTLBuffer> _Nonnull pointLightClusterIndicesBuffer;
    id <MTLBuffer> _Nonnull spotLightClusterIndicesBuffer;

    // Tile counts.
    NSUInteger              tileCountX;
    NSUInteger              tileCountY;

    NSUInteger              tileCountClusterX;
    NSUInteger              tileCountClusterY;

};

// Encapsulates the state for culling lights.
@interface AAPLLightCuller : NSObject

// Initializes this culling object, allocating compute pipelines.
- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                               library:(nonnull id<MTLLibrary>)library
                  useRasterizationRate:(BOOL)useRasterizationRate
            useLightCullingTileShaders:(BOOL)useTiledLightCulling
                  lightCullingTileSize:(uint)lightCullingTileSize
               lightClusteringTileSize:(uint)lightClusteringTileSize;

- (void)rebuildPipelinesWithLibrary:(nonnull id<MTLLibrary>)library
               useRasterizationRate:(BOOL)useRasterizationRate
         useLightCullingTileShaders:(BOOL)useLightCullingTileShaders;

// Initializes a LightCullResult object with buffers based on the view size and light counts.
- (LightCullResult)createResultInstance:(MTLSize)viewSize
                             lightCount:(simd::uint2)lightCount;

// Coarsely culls a set of lights to calculate their XY bounds.
- (void)executeCoarseCulling:(LightCullResult&)result
               commandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
             pointLightCount:(uint)pointLightCount
              spotLightCount:(uint)spotLightCount
                 pointLights:(nonnull id<MTLBuffer>)pointLights
                  spotLights:(nonnull id<MTLBuffer>)spotLights
             frameDataBuffer:(nonnull id<MTLBuffer>)frameDataBuffer
          cameraParamsBuffer:(nonnull id<MTLBuffer>)cameraParamsBuffer
                      rrData:(nullable id<MTLBuffer>)rrMapData
                   nearPlane:(float)nearPlane;

// Uses a traditional compute kernel to cull a set of lights based on depth,
//  using coarse culled results for XY range.
- (void)executeTraditionalCulling:(LightCullResult&)result
                  pointLightCount:(NSUInteger)pointLightCount
                   spotLightCount:(NSUInteger)spotLightCount
                      pointLights:(nonnull id<MTLBuffer>)pointLights
                       spotLights:(nonnull id<MTLBuffer>)spotLights
                  frameDataBuffer:(nonnull id<MTLBuffer>)frameDataBuffer
               cameraParamsBuffer:(nonnull id<MTLBuffer>)cameraParamsBuffer
                           rrData:(nullable id<MTLBuffer>)rrMapData
                     depthTexture:(nonnull id<MTLTexture>)depthTexture
                  onCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer;


// Uses a tile shader to both cull and cluster a set of lights based on depth,
//  using coarse culled results for XY range.
#if SUPPORT_LIGHT_CULLING_TILE_SHADERS
- (void)executeTileCulling:(LightCullResult&)result
                 clustered:(BOOL)clustered
           pointLightCount:(NSUInteger)pointLightCount
            spotLightCount:(NSUInteger)spotLightCount
               pointLights:(nonnull id<MTLBuffer>)pointLights
                spotLights:(nonnull id<MTLBuffer>)spotLights
           frameDataBuffer:(nonnull id<MTLBuffer>)frameDataBuffer
        cameraParamsBuffer:(nonnull id<MTLBuffer>)cameraParamsBuffer
                    rrData:(nullable id<MTLBuffer>)rrMapData
              depthTexture:(nonnull id<MTLTexture>)depthTexture
                 onEncoder:(nonnull id<MTLRenderCommandEncoder>)encoder;
#endif

// Executes traditional compute based light clustering.
- (void)executeTraditionalClustering:(LightCullResult&)result
                       commandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
                     pointLightCount:(uint)pointLightCount
                      spotLightCount:(uint)spotLightCount
                         pointLights:(nonnull id<MTLBuffer>)pointLights
                          spotLights:(nonnull id<MTLBuffer>)spotLights
                     frameDataBuffer:(nonnull id<MTLBuffer>)frameDataBuffer
                  cameraParamsBuffer:(nonnull id<MTLBuffer>)cameraParamsBuffer
                              rrData:(nullable id<MTLBuffer>)rrMapData;
@end
