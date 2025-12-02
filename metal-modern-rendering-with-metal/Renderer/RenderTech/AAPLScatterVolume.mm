/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of class which manages state to render a scatter volume
*/

#import "AAPLScatterVolume.h"
#import "AAPLShaderTypes.h"
#import "AAPLCommon.h"

#if USE_SCATTERING_VOLUME

@implementation AAPLScatterVolume
{
    // Device from initialization.
    id<MTLDevice>               _device;

    // Pipeline state for updating scattering from the previous frame.
    id<MTLComputePipelineState> _scatteringPipelineState;

    id<MTLComputePipelineState> _scatteringCLPipelineState;

    // Pipeline state to accumulate the current scattering state into the volume texture.
    id<MTLComputePipelineState> _scatteringAccumPipelineState;

    // Double buffered scattering volume storage.
    id<MTLTexture>              _scatteringVolume[2];
    int                         _scatteringVolumeIndex;

    uint _lightCullingTileSize;
    uint _lightClusteringTileSize;
}

- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                               library:(nonnull id<MTLLibrary>)library
                  useRasterizationRate:(BOOL)useRasterizationRate
                  lightCullingTileSize:(uint)lightCullingTileSize
               lightClusteringTileSize:(uint)lightClusteringTileSize
{
    self = [super init];
    if (self)
    {
        _lightCullingTileSize    = lightCullingTileSize;
        _lightClusteringTileSize = lightClusteringTileSize;

        _device = device;

        [self rebuildPipelinesWithLibrary:library useRasterizationRate:useRasterizationRate];
    }

    return self;
}

- (void)rebuildPipelinesWithLibrary:(nonnull id<MTLLibrary>)library
               useRasterizationRate:(BOOL)useRasterizationRate
{
    static const bool TRUE_VALUE = true;
    static const bool FALSE_VALUE = false;

    MTLFunctionConstantValues* fc = [MTLFunctionConstantValues new];

    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexLightCluster];
    [fc setConstantValue:&useRasterizationRate type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexRasterizationRate];
    [fc setConstantValue:&_lightCullingTileSize type:MTLDataTypeUInt atIndex:AAPLFunctionConstIndexLightCullingTileSize];
    [fc setConstantValue:&_lightClusteringTileSize type:MTLDataTypeUInt atIndex:AAPLFunctionConstIndexLightClusteringTileSize];
    _scatteringPipelineState = newComputePipelineState(library, @"kernelScattering",
                                                       @"ScatteringKernal", fc);

    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexLightCluster];

    _scatteringCLPipelineState = newComputePipelineState(library, @"kernelScattering",
                                                         @"ClusteredScatteringKernal", fc);

    _scatteringAccumPipelineState = newComputePipelineState(library, @"kernelAccumulateScattering",
                                                            @"AccumulateScatteringKernal", nil);
}

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
{
    _scatteringVolumeIndex = 1 - _scatteringVolumeIndex;

    id <MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    computeEncoder.label = @"ScatteringEncoder";

    [computeEncoder setBuffer:frameDataBuffer offset:0 atIndex:AAPLBufferIndexFrameData];
    [computeEncoder setBuffer:cameraParamsBuffer offset:0 atIndex:AAPLBufferIndexCameraParams];
#if SUPPORT_RASTERIZATION_RATE
    [computeEncoder setBuffer:rrMapData offset:0 atIndex:AAPLBufferIndexRasterizationRateMap];
#endif

    if (clustered)
        [computeEncoder setComputePipelineState:_scatteringCLPipelineState];
    else
        [computeEncoder setComputePipelineState:_scatteringPipelineState];

#if LOCAL_LIGHT_SCATTERING
    [computeEncoder setBuffer:pointLightBuffer offset:0 atIndex:AAPLBufferIndexPointLights];
    [computeEncoder setBuffer:spotLightBuffer offset:0 atIndex:AAPLBufferIndexSpotLights];
    [computeEncoder setBuffer:pointLightIndices offset:0 atIndex:AAPLBufferIndexPointLightIndices];
    [computeEncoder setBuffer:spotLightIndices offset:0 atIndex:AAPLBufferIndexSpotLightIndices];
#if USE_SPOT_LIGHT_SHADOWS
    [computeEncoder setTexture:spotLightShadows atIndex:5];
#endif // USE_SPOT_LIGHT_SHADOWS
#endif // LOCAL_LIGHT_SCATTERING

    [computeEncoder setTexture:_scatteringVolume[_scatteringVolumeIndex] atIndex:0];

    if(resetHistory)
        [computeEncoder setTexture:nil atIndex:1];
    else
        [computeEncoder setTexture:_scatteringVolume[1-_scatteringVolumeIndex] atIndex:1];

    [computeEncoder setTexture:_noiseTexture atIndex:2];
    [computeEncoder setTexture:_perlinNoiseTexture atIndex:3];
    [computeEncoder setTexture:shadowMap atIndex:4];

    {
        //MTLSize groupSize     = {1, 1, SCATTERING_VOLUME_DEPTH};
        MTLSize groupSize       = {4, 4, 4};
        MTLSize threadGroups    = divideRoundUp({_scatteringVolume[0].width, _scatteringVolume[0].height, _scatteringVolume[0].depth}, groupSize);

        [computeEncoder dispatchThreadgroups:threadGroups threadsPerThreadgroup:groupSize];
    }
    [computeEncoder setComputePipelineState:_scatteringAccumPipelineState];
    [computeEncoder setTexture:_scatteringAccumVolume atIndex:0];
    [computeEncoder setTexture:_scatteringVolume[_scatteringVolumeIndex] atIndex:1];

    {
        MTLSize groupSize       = {SCATTERING_TILE_SIZE, SCATTERING_TILE_SIZE, 1};
        MTLSize threadGroups    = divideRoundUp({_scatteringVolume[0].width, _scatteringVolume[0].height, 1}, groupSize);

        [computeEncoder dispatchThreadgroups:threadGroups threadsPerThreadgroup:groupSize];
    }

    [computeEncoder endEncoding];
}

- (void)resize:(CGSize)size
{
    MTLSize scatteringVolumeSize = divideRoundUp({(NSUInteger)size.width, (NSUInteger)size.height, 1},
                                                 {SCATTERING_TILE_SIZE, SCATTERING_TILE_SIZE, 1});

    bool validScatteringVolume = _scatteringVolume[0] != nil &&
        (_scatteringVolume[0].width == scatteringVolumeSize.width) &&
        (_scatteringVolume[0].height == scatteringVolumeSize.height);

    if (!validScatteringVolume)
    {
        MTLTextureDescriptor* desc =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA16Float
                                                           width:scatteringVolumeSize.width
                                                          height:scatteringVolumeSize.height
                                                       mipmapped:false];

        desc.textureType    = MTLTextureType3D;
        desc.depth          = SCATTERING_VOLUME_DEPTH;
        desc.storageMode    = MTLStorageModePrivate;
        desc.usage          = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;

        _scatteringVolume[0] = [_device newTextureWithDescriptor:desc];
        _scatteringVolume[0].label = @"Scattering Volume 0";

        _scatteringVolume[1] = [_device newTextureWithDescriptor:desc];
        _scatteringVolume[1].label = @"Scattering Volume 1";

        _scatteringAccumVolume = [_device newTextureWithDescriptor:desc];
        _scatteringAccumVolume.label = @"Scattering Volume Accum";
    }
}

@end

#endif
