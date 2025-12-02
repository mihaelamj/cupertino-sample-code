/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Compute functions for writing drop shadow information to a texture.
*/

#include <metal_stdlib>
using namespace metal;

#include "DropShadowComputeParams.h"

/// Remaps a value from one range to another.
float remap(float value, float2 fromRange, float2 toRange) {
   return toRange.x + (value - fromRange.x) * (toRange.y - toRange.x) / (fromRange.y - fromRange.x);
}

/// Updates the drop shadow map texture by writing information about the nearest drop shadow source to each pixel.
[[kernel]]
void updateDropShadowMap(device DropShadowComputeParams *dropShadowParams [[buffer(0)]],
                         constant uint &paramCount [[buffer(1)]],
                         texture2d<half, access::write> dropShadowTexture [[texture(2)]],
                         uint2 pixelCoords [[thread_position_in_grid]]) {
    // Skip out-of-bounds threads.
    // https://developer.apple.com/documentation/metal/compute_passes/calculating_threadgroup_and_grid_sizes
    uint2 dimensions = uint2(dropShadowTexture.get_width(), dropShadowTexture.get_height());
    if (all(pixelCoords >= dimensions)) { return; }
    
    // Get the position of the current pixel in level-space.
    float2 positionXZ = float2(remap(pixelCoords.x, float2(0, dimensions.x - 1), float2(-40, 40)),
                               remap(pixelCoords.y, float2(dimensions.y - 1, 0), float2(-40, 40)));
    
    // Write the nearest shadow source distance, position, and radius to the texture.
    half4 out = 0;
    float shortestDistanceSquared = INFINITY;
    for (uint index = 0; index < paramCount; index++) {
        float3 sourcePosition = dropShadowParams[index].sourcePosition;
        float distanceSquared = distance_squared(positionXZ, sourcePosition.xz);
        if (distanceSquared < shortestDistanceSquared) {
            out = half4(distanceSquared, sourcePosition.y, dropShadowParams[index].sourceShadowYPosition, dropShadowParams[index].sourceShadowRadius);
            shortestDistanceSquared = distanceSquared;
        }
    }
    dropShadowTexture.write(out, pixelCoords);
}

