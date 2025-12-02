/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of class which culls light volumes.
*/

#import <Foundation/Foundation.h>

#import "AAPLLightCuller.h"
#import "AAPLCommon.h"
#import "AAPLShaderTypes.h"

@implementation AAPLLightCuller
{
    // Device from initialization.
    id<MTLDevice>                   _device;

#if SUPPORT_LIGHT_CULLING_TILE_SHADERS
    // For Tiled Light Culling on TBDR Apple Silicon GPUs.
    id <MTLRenderPipelineState>  _renderCullingPipelineState;
    id <MTLRenderPipelineState>  _pipelineStateHierarchical;
    id <MTLRenderPipelineState>  _pipelineStateClustering;

    id <MTLRenderPipelineState>  _initTilePipelineState;
    id <MTLRenderPipelineState>  _depthBoundsTilePipelineState;
#endif

    // For compute based light culling on tradional GPUs.
    id <MTLComputePipelineState> _computeCullingPipelineState;

    // Common culling kenrels used on both traditional and TBDR GPUs.
    id <MTLComputePipelineState> _hierarchicalClusteredPipelineState;
    id <MTLComputePipelineState> _spotCoarseCullPipelineState;
    id <MTLComputePipelineState> _pointCoarseCullPipelineState;

    NSUInteger _lightCullingTileSize;
    NSUInteger _lightClusteringTileSize;
}

- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                               library:(id<MTLLibrary>)library
                  useRasterizationRate:(BOOL)useRasterizationRate
            useLightCullingTileShaders:(BOOL)useLightCullingTileShaders
                  lightCullingTileSize:(uint)lightCullingTileSize
               lightClusteringTileSize:(uint)lightClusteringTileSize
{
    self = [super init];
    if(self)
    {
        _device = device;

        _lightCullingTileSize    = lightCullingTileSize;
        _lightClusteringTileSize = lightClusteringTileSize;

        [self rebuildPipelinesWithLibrary:library
                     useRasterizationRate:useRasterizationRate
               useLightCullingTileShaders:useLightCullingTileShaders];
    }

    return self;
}

- (void)rebuildPipelinesWithLibrary:(nonnull id<MTLLibrary>)library
               useRasterizationRate:(BOOL)useRasterizationRate
         useLightCullingTileShaders:(BOOL)useLightCullingTileShaders
{
    MTLFunctionConstantValues* fc = [MTLFunctionConstantValues new];

    [fc setConstantValue:&useRasterizationRate type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexRasterizationRate];
    [fc setConstantValue:&_lightCullingTileSize type:MTLDataTypeUInt atIndex:AAPLFunctionConstIndexLightCullingTileSize];
    [fc setConstantValue:&_lightClusteringTileSize type:MTLDataTypeUInt atIndex:AAPLFunctionConstIndexLightClusteringTileSize];

#if !SUPPORT_LIGHT_CULLING_TILE_SHADERS
    NSAssert(!useLightCullingTileShaders, @"Tile Light Culling supported no enabled in build");
#else
    if(useLightCullingTileShaders)
    {
        NSError *error;

        MTLTileRenderPipelineDescriptor *tilePipelineStateDescriptor = [MTLTileRenderPipelineDescriptor new];
        MTLFunctionConstantValues* tilefc = [fc copy];

        tilePipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatR32Float;

        const simd::uint2 tileSize = { TILE_SHADER_WIDTH, TILE_SHADER_HEIGHT };
        const simd::uint2 depthBoundsDispatchSize = { TILE_DEPTH_BOUNDS_DISPATCH_SIZE, TILE_DEPTH_BOUNDS_DISPATCH_SIZE };

        [tilefc setConstantValue:&tileSize type:MTLDataTypeUInt2 atIndex:AAPLFunctionConstIndexTileSize];
        [tilefc setConstantValue:&depthBoundsDispatchSize type:MTLDataTypeUInt2 atIndex:AAPLFunctionConstIndexDispatchSize];

        tilePipelineStateDescriptor.tileFunction = [library newFunctionWithName:@"tileInit"];
        tilePipelineStateDescriptor.label = @"tileInit";

        _initTilePipelineState = [_device newRenderPipelineStateWithTileDescriptor:tilePipelineStateDescriptor options:MTLPipelineOptionNone reflection:nullptr error:&error];
        NSAssert(_initTilePipelineState, @"Failed to create initialization (tiled) tile pipeline state: %@", error);

        tilePipelineStateDescriptor.tileFunction = [library newFunctionWithName:@"tileDepthBounds" constantValues:tilefc error:&error];
        tilePipelineStateDescriptor.label = @"tileDepthBounds";
        _depthBoundsTilePipelineState = [_device newRenderPipelineStateWithTileDescriptor:tilePipelineStateDescriptor options:MTLPipelineOptionNone reflection:nullptr error:&error];
        NSAssert(_depthBoundsTilePipelineState, @"Failed to create depth bounds (tiled) tile pipeline state: %@", error);

        tilePipelineStateDescriptor.tileFunction = [library newFunctionWithName:@"tileLightCulling" constantValues:tilefc error:&error];
        tilePipelineStateDescriptor.label = @"tileLightCulling";
        _renderCullingPipelineState = [_device newRenderPipelineStateWithTileDescriptor:tilePipelineStateDescriptor options:MTLPipelineOptionNone reflection:nullptr error:&error];
        NSAssert(_renderCullingPipelineState, @"Failed to create light culling (tiled) tile pipeline state: %@", error);

        tilePipelineStateDescriptor.tileFunction = [library newFunctionWithName:@"tileLightCullingHierarchical" constantValues:tilefc error:&error];
        tilePipelineStateDescriptor.label = @"tileLightCullingHierarchical";
        _pipelineStateHierarchical = [_device newRenderPipelineStateWithTileDescriptor:tilePipelineStateDescriptor options:MTLPipelineOptionNone reflection:nullptr error:&error];
        NSAssert(_pipelineStateHierarchical, @"Failed to create light culling 2 (tiled) tile pipeline state: %@", error);

        tilePipelineStateDescriptor.tileFunction = [library newFunctionWithName:@"tileLightClustering" constantValues:tilefc error:&error];
        tilePipelineStateDescriptor.label = @"tileLightClustering";
        _pipelineStateClustering = [_device newRenderPipelineStateWithTileDescriptor:tilePipelineStateDescriptor options:MTLPipelineOptionNone reflection:nullptr error:&error];
        NSAssert(_pipelineStateClustering, @"Failed to create light culling (cluster) tile pipeline state: %@", error);
    }
    else
#endif
    {
        _computeCullingPipelineState = newComputePipelineState(library, @"traditionalLightCulling", @"LightCulling", fc);
    }

    _spotCoarseCullPipelineState = newComputePipelineState(library,@"kernelSpotLightCoarseCulling",
                                                           @"SpotLightCulling",
                                                           fc);
    _pointCoarseCullPipelineState = newComputePipelineState(library,@"kernelPointLightCoarseCulling",
                                                           @"PointLightCulling",
                                                            fc);
    _hierarchicalClusteredPipelineState = newComputePipelineState(library, @"traditionalLightClustering",
                                                                  @"LightClustring",
                                                                  fc);
}

- (void)executeCoarseCulling:(LightCullResult&)result
               commandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
             pointLightCount:(uint)pointLightCount
              spotLightCount:(uint)spotLightCount
                 pointLights:(nonnull id<MTLBuffer>)pointLights
                  spotLights:(nonnull id<MTLBuffer>)spotLights
             frameDataBuffer:(nonnull id<MTLBuffer>)frameDataBuffer
          cameraParamsBuffer:(nonnull id<MTLBuffer>)cameraParamsBuffer
                      rrData:(nullable id<MTLBuffer>)rrMapData
                   nearPlane:(float)nearPlane
{
    // The two dispatches in this encoder write to non-aliasing memory.
    id <MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoderWithDispatchType:MTLDispatchTypeConcurrent];
    computeEncoder.label = @"LightCoarseCulling";

    [computeEncoder setComputePipelineState:_pointCoarseCullPipelineState];
    [computeEncoder setBuffer:frameDataBuffer offset:0 atIndex:AAPLBufferIndexFrameData];
    [computeEncoder setBuffer:cameraParamsBuffer offset:0 atIndex:AAPLBufferIndexCameraParams];
    [computeEncoder setBytes:&nearPlane length:sizeof(nearPlane) atIndex:AAPLBufferIndexNearPlane];

#if SUPPORT_RASTERIZATION_RATE
    [computeEncoder setBuffer:rrMapData offset:0 atIndex:AAPLBufferIndexRasterizationRateMap];
#endif

    if (pointLightCount > 0)
    {
        [computeEncoder setBuffer:pointLights offset:0 atIndex:AAPLBufferIndexPointLights];
        [computeEncoder setBytes:&pointLightCount length:sizeof(pointLightCount) atIndex:AAPLBufferIndexLightCount];
        [computeEncoder setBuffer:result.pointLightXYCoarseCullIndicesBuffer offset:0 atIndex:AAPLBufferIndexPointLightCoarseCullingData];

        [computeEncoder dispatchThreadgroups:{ divideRoundUp(pointLightCount, 64), 1, 1} threadsPerThreadgroup:{ 64, 1, 1 }];
    }

    if (spotLightCount > 0)
    {
        [computeEncoder setComputePipelineState:_spotCoarseCullPipelineState];
        [computeEncoder setBuffer:spotLights offset:0 atIndex:AAPLBufferIndexSpotLights];
        [computeEncoder setBytes:&spotLightCount length:sizeof(spotLightCount) atIndex:AAPLBufferIndexLightCount];
        [computeEncoder setBuffer:result.spotLightXYCoarseCullIndicesBuffer offset:0 atIndex:AAPLBufferIndexSpotLightCoarseCullingData];

        [computeEncoder dispatchThreadgroups:{ divideRoundUp(spotLightCount, 64), 1, 1} threadsPerThreadgroup:{ 64, 1, 1 }];
    }

    [computeEncoder endEncoding];
}

- (LightCullResult)createResultInstance:(MTLSize)viewSize
                             lightCount:(simd::uint2)lightCount
{
    LightCullResult inst;

    inst.tileCountX = divideRoundUp(viewSize.width, _lightCullingTileSize);
    inst.tileCountY = divideRoundUp(viewSize.height, _lightCullingTileSize);

    NSUInteger tileCount = inst.tileCountX * inst.tileCountY;

    inst.pointLightIndicesBuffer                        = [_device newBufferWithLength:tileCount * MAX_LIGHTS_PER_TILE * sizeof(uint8_t) options:MTLResourceStorageModePrivate];
    inst.pointLightIndicesBuffer.label                  = [NSString stringWithFormat:@"Point Light Indices (1B/l x %d l/tile x %u tiles)", MAX_LIGHTS_PER_TILE, unsigned(tileCount)];

    inst.pointLightIndicesTransparentBuffer             = [_device newBufferWithLength:tileCount * MAX_LIGHTS_PER_TILE * sizeof(uint8_t) options:MTLResourceStorageModePrivate];
    inst.pointLightIndicesTransparentBuffer.label       = [NSString stringWithFormat:@"Point Light Indices Transparent (1B/l x %d l/tile x %u tiles)", MAX_LIGHTS_PER_TILE, unsigned(tileCount)];

    inst.spotLightIndicesBuffer                         = [_device newBufferWithLength:tileCount * MAX_LIGHTS_PER_TILE * sizeof(uint8_t) options:MTLResourceStorageModePrivate];
    inst.spotLightIndicesBuffer.label                   = [NSString stringWithFormat:@"Spot Light Indices (1B/l x %d l/tile x %u tiles)", MAX_LIGHTS_PER_TILE, unsigned(tileCount)];

    inst.spotLightIndicesTransparentBuffer              = [_device newBufferWithLength:tileCount * MAX_LIGHTS_PER_TILE * sizeof(uint8_t) options:MTLResourceStorageModePrivate];
    inst.spotLightIndicesTransparentBuffer.label        = [NSString stringWithFormat:@"Spot Light Indices Transparent (1B/l x %d l/tile x %u tiles)", MAX_LIGHTS_PER_TILE, unsigned(tileCount)];

    NSUInteger pointLightCount = MAX(lightCount.x, 1u);
    NSUInteger spotLightCount = MAX(lightCount.y, 1u);
    inst.pointLightXYCoarseCullIndicesBuffer            = [_device newBufferWithLength:pointLightCount * sizeof(simd::ushort4) options:MTLResourceStorageModePrivate];
    inst.pointLightXYCoarseCullIndicesBuffer.label      = [NSString stringWithFormat:@"Point Light Coarse Cull XY (8B/l x %lu l)", (unsigned long)pointLightCount];

    inst.spotLightXYCoarseCullIndicesBuffer             = [_device newBufferWithLength:spotLightCount * sizeof(simd::ushort4) options:MTLResourceStorageModePrivate];
    inst.spotLightXYCoarseCullIndicesBuffer.label       = [NSString stringWithFormat:@"Spot Light Coarse Cull XY (8B/l x %lu l)", (unsigned long)spotLightCount];

    inst.tileCountClusterX = divideRoundUp(viewSize.width, _lightCullingTileSize);
    inst.tileCountClusterY = divideRoundUp(viewSize.height, _lightCullingTileSize);
    NSUInteger clusterCount = inst.tileCountClusterX * inst.tileCountClusterY * LIGHT_CLUSTER_DEPTH;

    inst.pointLightClusterIndicesBuffer            = [_device newBufferWithLength:clusterCount * MAX_LIGHTS_PER_CLUSTER * sizeof(uint8_t) options:MTLResourceStorageModePrivate];
    inst.pointLightClusterIndicesBuffer.label      = [NSString stringWithFormat:@"Point Light Cluster Indices (1B/l x %d l/cluster x %u clusters)", MAX_LIGHTS_PER_CLUSTER, unsigned(clusterCount)];

    inst.spotLightClusterIndicesBuffer             = [_device newBufferWithLength:clusterCount * MAX_LIGHTS_PER_CLUSTER * sizeof(uint8_t) options:MTLResourceStorageModePrivate];
    inst.spotLightClusterIndicesBuffer.label       = [NSString stringWithFormat:@"Spot Light Cluster Indices (1B/l x %d l/cluster x %u clusters)", MAX_LIGHTS_PER_CLUSTER, unsigned(clusterCount)];

    return inst;
}

- (void)executeTraditionalCulling:(LightCullResult&)result
                  pointLightCount:(NSUInteger)pointLightCount
                   spotLightCount:(NSUInteger)spotLightCount
                      pointLights:(nonnull id<MTLBuffer>)pointLights
                       spotLights:(nonnull id<MTLBuffer>)spotLights
                  frameDataBuffer:(nonnull id<MTLBuffer>)frameDataBuffer
               cameraParamsBuffer:(nonnull id<MTLBuffer>)cameraParamsBuffer
                           rrData:(nullable id<MTLBuffer>)rrMapData
                     depthTexture:(nonnull id<MTLTexture>)depthTexture
                  onCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
{

    id <MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
    encoder.label = @"LightCulling";

    [encoder setComputePipelineState:_computeCullingPipelineState]; // `traditionalLightCulling` kernel.
    [encoder setBuffer:result.pointLightIndicesBuffer offset:0 atIndex:AAPLBufferIndexPointLightIndices];
    [encoder setBuffer:result.pointLightIndicesTransparentBuffer offset:0 atIndex:AAPLBufferIndexTransparentPointLightIndices];
    [encoder setBuffer:result.spotLightIndicesBuffer offset:0 atIndex:AAPLBufferIndexSpotLightIndices];
    [encoder setBuffer:result.spotLightIndicesTransparentBuffer offset:0 atIndex:AAPLBufferIndexTransparentSpotLightIndices];

    [encoder setBuffer:frameDataBuffer offset:0 atIndex:AAPLBufferIndexFrameData];
    [encoder setBuffer:cameraParamsBuffer offset:0 atIndex:AAPLBufferIndexCameraParams];
    [encoder setBuffer:pointLights offset:0 atIndex:AAPLBufferIndexPointLights];
    [encoder setBuffer:spotLights offset:0 atIndex:AAPLBufferIndexSpotLights];

    uint lightCount[2] = { (uint)pointLightCount, (uint)spotLightCount };
    [encoder setBytes:&lightCount length:sizeof(lightCount) atIndex:AAPLBufferIndexLightCount];
    [encoder setTexture:depthTexture atIndex:0];

#if SUPPORT_RASTERIZATION_RATE
    [encoder setBuffer:rrMapData offset:0 atIndex:AAPLBufferIndexRasterizationRateMap];
#endif

    [encoder setBuffer:result.pointLightXYCoarseCullIndicesBuffer offset:0 atIndex:AAPLBufferIndexPointLightCoarseCullingData];
    [encoder setBuffer:result.spotLightXYCoarseCullIndicesBuffer offset:0 atIndex:AAPLBufferIndexSpotLightCoarseCullingData];

    [encoder dispatchThreadgroups:{ result.tileCountX, result.tileCountY, 1} threadsPerThreadgroup:{ 16, 16, 1 }];

    [encoder endEncoding];
}

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
                 onEncoder:(nonnull id<MTLRenderCommandEncoder>)encoder
{
    [encoder setRenderPipelineState:_initTilePipelineState]; // `tileInit` kernel.
    [encoder dispatchThreadsPerTile:MTLSizeMake(1, 1, 1)];

    [encoder setTileBuffer:cameraParamsBuffer offset:0 atIndex:AAPLBufferIndexCameraParams];

    [encoder setRenderPipelineState:_depthBoundsTilePipelineState];  // `tileDepthBounds` kernel.
    [encoder dispatchThreadsPerTile:MTLSizeMake(TILE_DEPTH_BOUNDS_DISPATCH_SIZE, TILE_DEPTH_BOUNDS_DISPATCH_SIZE, 1)];

    [encoder setTileBuffer:result.pointLightIndicesBuffer offset:0 atIndex:AAPLBufferIndexPointLightIndices];
    [encoder setTileBuffer:result.pointLightIndicesTransparentBuffer offset:0 atIndex:AAPLBufferIndexTransparentPointLightIndices];
    [encoder setTileBuffer:result.spotLightIndicesBuffer offset:0 atIndex:AAPLBufferIndexSpotLightIndices];
    [encoder setTileBuffer:result.spotLightIndicesTransparentBuffer offset:0 atIndex:AAPLBufferIndexTransparentSpotLightIndices];
    [encoder setTileBuffer:frameDataBuffer offset:0 atIndex:AAPLBufferIndexFrameData];
    [encoder setTileBuffer:pointLights offset:0 atIndex:AAPLBufferIndexPointLights];
    [encoder setTileBuffer:spotLights offset:0 atIndex:AAPLBufferIndexSpotLights];

    uint lightCount[2] = { (uint)pointLightCount, (uint)spotLightCount };
    [encoder setTileBytes:&lightCount length:sizeof(lightCount) atIndex:AAPLBufferIndexLightCount];
    [encoder setTileBuffer:result.pointLightXYCoarseCullIndicesBuffer offset:0 atIndex:AAPLBufferIndexPointLightCoarseCullingData];
    [encoder setTileBuffer:result.spotLightXYCoarseCullIndicesBuffer offset:0 atIndex:AAPLBufferIndexSpotLightCoarseCullingData];

#if SUPPORT_RASTERIZATION_RATE
    [encoder setTileBuffer:rrMapData offset:0 atIndex:AAPLBufferIndexRasterizationRateMap];
#endif

#if SUPPORT_LIGHT_CLUSTERING_TILE_SHADER
    if (clustered)
    {
        [encoder setRenderPipelineState:_pipelineStateHierarchical]; // `tileLightCullingHierarchical` kernel
        [encoder dispatchThreadsPerTile:MTLSizeMake(TILE_SHADER_WIDTH, TILE_SHADER_HEIGHT, 1)];

        [encoder setTileBuffer:result.pointLightClusterIndicesBuffer offset:0 atIndex:AAPLBufferIndexPointLightIndices];
        [encoder setTileBuffer:result.spotLightClusterIndicesBuffer offset:0 atIndex:AAPLBufferIndexSpotLightIndices];

        [encoder setRenderPipelineState:_pipelineStateClustering]; // `tileLightClustering` kernel
        [encoder dispatchThreadsPerTile:MTLSizeMake(8, 8, 1)];
    }
    else
#endif
    {
        [encoder setRenderPipelineState:_renderCullingPipelineState]; // `tileLightCulling` kernel
        [encoder dispatchThreadsPerTile:MTLSizeMake(TILE_SHADER_WIDTH, TILE_SHADER_HEIGHT, 1)];
    }
}
#endif

- (void)executeTraditionalClustering:(LightCullResult&)result
                       commandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
                     pointLightCount:(uint)pointLightCount
                      spotLightCount:(uint)spotLightCount
                         pointLights:(nonnull id<MTLBuffer>)pointLights
                          spotLights:(nonnull id<MTLBuffer>)spotLights
                     frameDataBuffer:(nonnull id<MTLBuffer>)frameDataBuffer
                  cameraParamsBuffer:(nonnull id<MTLBuffer>)cameraParamsBuffer
                              rrData:(nullable id<MTLBuffer>)rrMapData
{
    uint lightCount[2] = { (uint)pointLightCount, (uint)spotLightCount };

    id <MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
    encoder.label = @"LightClustering";

    [encoder setBuffer:result.pointLightClusterIndicesBuffer offset:0 atIndex:AAPLBufferIndexPointLightIndices];
    [encoder setBuffer:result.pointLightIndicesTransparentBuffer offset:0 atIndex:AAPLBufferIndexTransparentPointLightIndices];
    [encoder setBuffer:result.spotLightClusterIndicesBuffer offset:0 atIndex:AAPLBufferIndexSpotLightIndices];
    [encoder setBuffer:result.spotLightIndicesTransparentBuffer offset:0 atIndex:AAPLBufferIndexTransparentSpotLightIndices];

    [encoder setBuffer:frameDataBuffer offset:0 atIndex:AAPLBufferIndexFrameData];
    [encoder setBuffer:cameraParamsBuffer offset:0 atIndex:AAPLBufferIndexCameraParams];
    [encoder setBuffer:pointLights offset:0 atIndex:AAPLBufferIndexPointLights];
    [encoder setBuffer:spotLights offset:0 atIndex:AAPLBufferIndexSpotLights];

    [encoder setBytes:&lightCount length:sizeof(lightCount) atIndex:AAPLBufferIndexLightCount];
#if SUPPORT_RASTERIZATION_RATE
    [encoder setBuffer:rrMapData offset:0 atIndex:AAPLBufferIndexRasterizationRateMap];
#endif
    [encoder setBuffer:result.pointLightXYCoarseCullIndicesBuffer offset:0 atIndex:10];
    [encoder setBuffer:result.spotLightXYCoarseCullIndicesBuffer offset:0 atIndex:11];

    [encoder setComputePipelineState:_hierarchicalClusteredPipelineState]; // `traditionalLightClustering` kernel
    [encoder dispatchThreadgroups:{ result.tileCountClusterX, result.tileCountClusterY, 1 }
            threadsPerThreadgroup:{ 1, 1, LIGHT_CLUSTER_DEPTH }];
    [encoder endEncoding];
}

@end
