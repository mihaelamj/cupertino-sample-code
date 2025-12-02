/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Shaders implementing debug rendering utilities.
*/

#import "AAPLShaderCommon.h"

//------------------------------------------------------------------------------

constant bool gUseRasterizationRate    [[function_constant(AAPLFunctionConstIndexRasterizationRate)]];

constant uint gLightCullingTileSize    [[function_constant(AAPLFunctionConstIndexLightCullingTileSize)]];

constant uint gLightClusteringTileSize [[function_constant(AAPLFunctionConstIndexLightClusteringTileSize)]];
//------------------------------------------------------------------------------

// Checks if a pixel is on the border of a tile.
static bool isBorder(uint2 xy, uint tileSize)
{
    uint pixel_in_tile_x = (uint)xy.x % tileSize;
    uint pixel_in_tile_y = (uint)xy.y % tileSize;
    return ((pixel_in_tile_x == 0)
            | (pixel_in_tile_y == 0)
            | (pixel_in_tile_x == tileSize-1)
            | (pixel_in_tile_y == tileSize-1));
}

#define DEBUG_MAX_LIGHTS (12)

// Fragment shader to render a heatmap color based on the light count for the tile.
fragment float4 fragmentLightHeatmapShader(AAPLSimpleVertexOut in                           [[stage_in]],
                                           device uint8_t *pointLightIndices                [[buffer(AAPLBufferIndexPointLightIndices)]],
                                           device uint8_t *spotLightIndices                 [[buffer(AAPLBufferIndexSpotLightIndices)]],
                                           device uint8_t *pointLightTransparentIndices     [[buffer(AAPLBufferIndexTransparentPointLightIndices)]],
                                           device uint8_t *spotLightTransparentIndices      [[buffer(AAPLBufferIndexTransparentSpotLightIndices)]],
                                           constant float4 &params                          [[buffer(AAPLBufferIndexHeatmapParams)]],
                                           constant rasterization_rate_map_data * rrData    [[buffer(AAPLBufferIndexRasterizationRateMap), function_constant(gUseRasterizationRate)]],
                                           device AAPLFrameConstants & frameData            [[buffer(AAPLBufferIndexFrameData)]])
{
    uint2 screenPos = uint2(in.position.xy);
#if SUPPORT_RASTERIZATION_RATE
    if (gUseRasterizationRate)
    {
        // This heat map is composited after restoring original screen space.
        // We convert back to physical space to find the original light tile.
        rasterization_rate_map_decoder decoder(*rrData);
        screenPos = decoder.map_screen_to_physical_coordinates(screenPos);
    }
#endif

    uint tile_x = screenPos.x / gLightCullingTileSize;
    uint tile_y = screenPos.y / gLightCullingTileSize;

    uint tileIdx = (tile_x + params.x * tile_y) * MAX_LIGHTS_PER_TILE;

    uint32_t pointLightCount = pointLightIndices[tileIdx];
    uint32_t spotLightCount = spotLightIndices[tileIdx];
    uint32_t lightCount = pointLightCount + spotLightCount;

    uint32_t pointLightTransparentCount = pointLightTransparentIndices[tileIdx];
    uint32_t spotLightTransparentCount = spotLightTransparentIndices[tileIdx];
    uint32_t lightTransparentCount = pointLightTransparentCount + spotLightTransparentCount;

    float blendTransparentStrength = params.z;

    float4 heatmap              = getHeatmapColor(lightCount, DEBUG_MAX_LIGHTS);
    float4 heatmapTransparent   = getHeatmapColor(lightTransparentCount, DEBUG_MAX_LIGHTS);

    float4 result = mix(heatmap, heatmapTransparent, blendTransparentStrength);
    if(isBorder(screenPos, gLightCullingTileSize))
        result.w *= 0.25f;
    return result;
}

fragment float4 fragmentLightClusterHeatmapShader(AAPLSimpleTexVertexOut in                      [[stage_in]],
                                                  device uint8_t *pointLightIndices              [[buffer(AAPLBufferIndexPointLightIndices)]],
                                                  device uint8_t *spotLightIndices               [[buffer(AAPLBufferIndexSpotLightIndices)]],
                                                  constant float4 &params                        [[buffer(AAPLBufferIndexHeatmapParams)]],
                                                  constant AAPLCameraParams & cameraParams       [[buffer(AAPLBufferIndexCameraParams)]],
                                                  constant rasterization_rate_map_data * rrData  [[buffer(AAPLBufferIndexFrameData), function_constant(gUseRasterizationRate)]],
                                                  depth2d<float, access::sample>   inDepth       [[texture(0)]])
{
    uint2 screenPos = uint2(in.position.xy);
#if SUPPORT_RASTERIZATION_RATE
    if (gUseRasterizationRate)
    {
        // This heat map is composited after restoring original screen space.
        // We convert back to physical space to find the original light tile.
        rasterization_rate_map_decoder decoder(*rrData);
        screenPos = decoder.map_screen_to_physical_coordinates(screenPos);
    }
#endif

    uint tile_x = screenPos.x / gLightCullingTileSize;
    uint tile_y = screenPos.y / gLightCullingTileSize;

    constexpr sampler nearestSampler(mip_filter::nearest, mag_filter::nearest, min_filter::nearest, address::clamp_to_edge);
    const float depth = inDepth.sample(nearestSampler, in.texCoord);
    float linearDepth = linearizeDepth(cameraParams, depth);

#if LOCAL_LIGHT_SCATTERING
    uint zcluster = zToScatterDepth(linearDepth) * LIGHT_CLUSTER_DEPTH;
#else
    float depthStep = LIGHT_CLUSTER_RANGE / LIGHT_CLUSTER_DEPTH;
    uint zcluster = linearDepth / depthStep;
#endif

    uint tileIdx = (tile_x + params.x * tile_y + zcluster * params.y) * MAX_LIGHTS_PER_CLUSTER;

    uint32_t pointLightCount = pointLightIndices[tileIdx];
    uint32_t spotLightCount = spotLightIndices[tileIdx];
    uint32_t lightCount = pointLightCount + spotLightCount;

    uint32_t lightTransparentCount = pointLightCount + spotLightCount;

    for(int i = 0; i < LIGHT_CLUSTER_DEPTH; ++i)
    {
        uint tileIdx = (tile_x + params.x * tile_y + i * params.y) * MAX_LIGHTS_PER_CLUSTER;

        uint32_t pointLightCount = pointLightIndices[tileIdx];
        uint32_t spotLightCount = spotLightIndices[tileIdx];
        lightTransparentCount = max(lightTransparentCount, pointLightCount + spotLightCount);
    }

    float blendTransparentStrength = params.z;

    float4 heatmap              = getHeatmapColor(lightCount, DEBUG_MAX_LIGHTS);
    float4 heatmapTransparent   = getHeatmapColor(lightTransparentCount, DEBUG_MAX_LIGHTS);

    float4 result = mix(heatmap, heatmapTransparent, blendTransparentStrength);

    if(isBorder(screenPos, gLightClusteringTileSize))
        result.w *= 0.25f;

    return result;
}
