/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for generic types shared between Metal shader code and ObjC .
*/
#import <simd/simd.h>

#import "../AAPLConfig.h"

// Global function constant indices.
typedef enum AAPLFunctionConstIndex
{
    AAPLFunctionConstIndexAlphaMask,
    AAPLFunctionConstIndexTransparent,
    AAPLFunctionConstIndexTileSize,
    AAPLFunctionConstIndexDispatchSize,
    AAPLFunctionConstIndexDebugView,
    AAPLFunctionConstIndexLightCluster,
    AAPLFunctionConstIndexRasterizationRate,
    AAPLFunctionConstIndexSinglePassDeferred,
    AAPLFunctionConstIndexLightCullingTileSize,
    AAPLFunctionConstIndexLightClusteringTileSize,
    AAPLFunctionConstIndexUseOcclusionCulling,
    AAPLFunctionConstIndexEncodeAlphaMask,
    AAPLFunctionConstIndexEncodeToDepthOnly,
    AAPLFunctionConstIndexEncodeToMain,
    AAPLFunctionConstIndexVisualizeCulling,
    AAPLFunctionConstIndexPackCommands,
    AAPLFunctionConstIndexFilteredCulling,
    AAPLFunctionConstIndexTemporalAntialiasing
} AAPLFunctionConstIndex;

// Indices for GBuffer render targets.
typedef enum AAPLGBufferIndex
{
#if SUPPORT_SINGLE_PASS_DEFERRED
    AAPLGBufferLightIndex = 0,
#endif
    AAPLTraditionalGBufferStart,
    AAPLGBufferAlbedoAlphaIndex = AAPLTraditionalGBufferStart,
    AAPLGBufferNormalsIndex,
    AAPLGBufferEmissiveIndex,
    AAPLGBufferF0RoughnessIndex,
    AAPLGBufferIndexCount,
} AAPLGBufferIndex;

// Indices for buffer bindings.
typedef enum AAPLBufferIndex
{
    AAPLBufferIndexFrameData = 0,
    AAPLBufferIndexCameraParams,
    AAPLBufferIndexRasterizationRateMap,
    AAPLBufferIndexCommonCount,

    AAPLBufferIndexCullParams = AAPLBufferIndexFrameData,

    AAPLBufferIndexVertexMeshPositions = AAPLBufferIndexCommonCount,
    AAPLBufferIndexVertexMeshGenerics,
    AAPLBufferIndexVertexMeshNormals,
    AAPLBufferIndexVertexMeshTangents,
    AAPLBufferIndexVertexCount,

    AAPLBufferIndexFragmentMaterial = AAPLBufferIndexCommonCount,
    AAPLBufferIndexFragmentGlobalTextures,
    AAPLBufferIndexFragmentLightParams,
    AAPLBufferIndexFragmentChunkViz,
    AAPLBufferIndexFragmentCount,

    AAPLBufferIndexPointLights = AAPLBufferIndexCommonCount,
    AAPLBufferIndexSpotLights,
    AAPLBufferIndexLightCount,
    AAPLBufferIndexPointLightIndices,
    AAPLBufferIndexSpotLightIndices,
    AAPLBufferIndexTransparentPointLightIndices,
    AAPLBufferIndexTransparentSpotLightIndices,
    AAPLBufferIndexPointLightCoarseCullingData,
    AAPLBufferIndexSpotLightCoarseCullingData,
    AAPLBufferIndexNearPlane,
    AAPLBufferIndexHeatmapParams,
    AAPLBufferIndexDepthPyramidSize,

    AAPLBufferIndexComputeEncodeArguments = AAPLBufferIndexCommonCount,
    AAPLBufferIndexComputeCullCameraParams,
#if SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
    AAPLBufferIndexComputeCullCameraParams2,
#endif
    AAPLBufferIndexComputeFrameData,
    AAPLBufferIndexComputeMaterial,
    AAPLBufferIndexComputeChunks,
    AAPLBufferIndexComputeChunkViz,
    AAPLBufferIndexComputeExecutionRange,
    AAPLBufferIndexComputeCount,

    AAPLBufferIndexVertexDepthOnlyICBBufferCount            = AAPLBufferIndexVertexMeshPositions+1,
    AAPLBufferIndexVertexDepthOnlyICBAlphaMaskBufferCount   = AAPLBufferIndexVertexMeshGenerics+1,
    AAPLBufferIndexVertexICBBufferCount                     = AAPLBufferIndexVertexCount,

    AAPLBufferIndexFragmentICBBufferCount                   = AAPLBufferIndexFragmentCount,
    AAPLBufferIndexFragmentDepthOnlyICBAlphaMaskBufferCount = AAPLBufferIndexFragmentMaterial+1,
} AAPLBufferIndex;

// Indices for vertex attributes.
typedef enum AAPLVertexAttribute
{
    AAPLVertexAttributePosition = 0,
    AAPLVertexAttributeNormal   = 1,
    AAPLVertexAttributeTangent  = 2,
    AAPLVertexAttributeTexcoord = 3,
} AAPLVertexAttribute;

// Indices for members of the AAPLShaderMaterial argument buffer.
typedef enum AAPLMaterialIndex
{
    AAPLMaterialIndexBaseColor,
    AAPLMaterialIndexMetallicRoughness,
    AAPLMaterialIndexNormal,
    AAPLMaterialIndexEmissive,
    AAPLMaterialIndexAlpha,
    AAPLMaterialIndexHasMetallicRoughness,
    AAPLMaterialIndexHasEmissive,

#if USE_TEXTURE_STREAMING
    AAPLMaterialIndexBaseColorMip,
    AAPLMaterialIndexMetallicRoughnessMip,
    AAPLMaterialIndexNormalMip,
    AAPLMaterialIndexEmissiveMip,
#endif
} AAPLMaterialIndex;

// Indices for members of the AAPLShaderLightParams argument buffer.
typedef enum AAPLLightParamsIndex
{
    AAPLLightParamsIndexPointLights,
    AAPLLightParamsIndexSpotLights,
    AAPLLightParamsIndexPointLightIndices,
    AAPLLightParamsIndexSpotLightIndices,
    AAPLLightParamsIndexPointLightIndicesTransparent,
    AAPLLightParamsIndexSpotLightIndicesTransparent,
} AAPLLightParamsIndex;

// Indices for members of the AAPLGlobalTextures argument buffer.
typedef enum AAPLGlobalTextureIndexd
{
    AAPLGlobalTextureIndexViewDepthPyramid,
    AAPLGlobalTextureIndexShadowMap,
    AAPLGlobalTextureIndexDFG,
    AAPLGlobalTextureIndexEnvMap,
    AAPLGlobalTextureIndexBlueNoise,
    AAPLGlobalTextureIndexPerlinNoise,
    AAPLGlobalTextureIndexSAO,
    AAPLGlobalTextureIndexScattering,
    AAPLGlobalTextureIndexSpotShadows,
}AAPLGlobalTextureIndexd;

// Indices for threadgroup storage during tiled light culling.
typedef enum AAPLTileThreadgroupIndex
{
    AAPLTileThreadgroupIndexDepthBounds,
    AAPLTileThreadgroupIndexLightCounts,
    AAPLTileThreadgroupIndexTransparentPointLights,
    AAPLTileThreadgroupIndexTransparentSpotLights,
    AAPLTileThreadgroupIndexScatteringVolume,
} AAPLTileThreadgroupIndex;

// Options for culling visualization.
typedef enum AAPLVisualizationType
{
    AAPLVisualizationTypeNone,
    AAPLVisualizationTypeChunkIndex,
    AAPLVisualizationTypeCascadeCount,
    AAPLVisualizationTypeFrustum,
    AAPLVisualizationTypeFrustumCull,
    AAPLVisualizationTypeFrustumCullOcclusion,
    AAPLVisualizationTypeFrustumCullOcclusionCull,
    AAPLVisualizationTypeCount
} AAPLVisualizationType;

// Matrices stored and generated internally within the camera object.
typedef struct AAPLCameraParams
{
    // Standard camera matrices.
    simd::float4x4      viewMatrix;
    simd::float4x4      projectionMatrix;
    simd::float4x4      viewProjectionMatrix;

    // Inverse matrices.
    simd::float4x4      invViewMatrix;
    simd::float4x4      invProjectionMatrix;
    simd::float4x4      invViewProjectionMatrix;

    // Frustum planes in world space.
    simd::float4        worldFrustumPlanes[6];

    // A float4 containing the lower right 2x2 z,w block of inv projection matrix (column major);
    //   viewZ = (X * projZ + Z) / (Y * projZ + W)
    simd::float4        invProjZ;

    // Same as invProjZ but the result is a Z from 0...1 instead of N...F;
    //  effectively linearizes Z for easy visualization/storage.
    simd::float4        invProjZNormalized;
} AAPLCameraParams;

// Frame data common to most shaders.
typedef struct AAPLFrameConstants
{
    AAPLCameraParams cullParams;       // Parameters for culling.
    AAPLCameraParams shadowCameraParams[SHADOW_CASCADE_COUNT]; // Camera data for cascade shadows cameras.

    // Previous view projection matrix for temporal reprojection.
    simd::float4x4      prevViewProjectionMatrix;

    // Screen resolution and inverse for texture sampling.
    simd::float2        screenSize;
    simd::float2        invScreenSize;

    // Physical resolution and inverse for adjusting between screen and physical space.
    simd::float2        physicalSize;
    simd::float2        invPhysicalSize;

    // Lighting environment
    simd::float3        sunDirection;
    simd::float3        sunColor;
    simd::float3        skyColor;
    float               exposure;
    float               localLightIntensity;
    float               iblScale;
    float               iblSpecularScale;
    float               emissiveScale;
    float               scatterScale;
    float               wetness;

    simd::float3        globalNoiseOffset;

    simd::uint4         lightIndicesParams;

    // Distance scale for scattering.
    float               oneOverFarDistance;

    // Frame counter and time for varying values over frames and time.
    uint                frameCounter;
    float               frameTime;

    // Debug settings.
    uint                debugView;
    uint                visualizeCullingMode;
    uint                debugToggle;
} AAPLFrameConstants;

// Point light information.
typedef struct AAPLPointLightData
{
    simd::float4    posSqrRadius;   // Position in XYZ, radius squared in W.
    simd::float3    color;          // RGB color of light.
    uint            flags;          // Optional flags. May include `LIGHT_FOR_TRANSPARENT_FLAG`.
} AAPLPointLightData;

// Spot light information.
typedef struct AAPLSpotLightData
{
    simd::float4    boundingSphere;     // Bounding sphere for quick visibility test.
    simd::float4    posAndHeight;       // Position in XYZ and height of spot in W.
    simd::float4    colorAndInnerAngle; // RGB color of light.
    simd::float4    dirAndOuterAngle;   // Direction in XYZ, cone angle in W.
    simd::float4x4  viewProjMatrix;     // View projection matrix to light space.
    uint            flags;              // Optional flags. May include `LIGHT_FOR_TRANSPARENT_FLAG`.

} AAPLSpotLightData;

// Point light information for culling.
typedef struct AAPLPointLightCullingData
{
    simd::float4    posRadius;          // Bounding sphere position in XYZ and radius of sphere in W.
                                        // Sign of radius:
                                        //  positive - transparency affecting light
                                        //  negative - light does not affect transparency
} AAPLPointLightCullingData;

// Spot light information for culling.
typedef struct AAPLSpotLightCullingData
{
    simd::float4    posRadius;          // Bounding sphere position in XYZ and radius of sphere in W.
                                        // Sign of radius:
                                        //  positive - transparency affecting light
                                        //  negative - light does not affect transparency
    simd::float4    posAndHeight;       // View space position in XYZ and height of spot in W.
    simd::float4    dirAndOuterAngle;   // View space direction in XYZ and cosine of outer angle in W.
} AAPLSpotLightCullingData;
