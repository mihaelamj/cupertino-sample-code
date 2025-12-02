/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Compute shader operations for sculpting.
*/

#include <metal_stdlib>

using namespace metal;

#include "../Volume/VolumeParams.h"
#include "SculptParams.h"

float distanceFromDot(float3 position, float3 center, float radius) {
    return length(position - center) - radius;
}

float distanceFromCappedLine(float3 position, float3 endpointA, float3 endpointB, float radius) {
    float3 positionToEndpoint = position - endpointA;
    float3 lineLength = endpointB - endpointA;
    float distanceBetweenEndpoints = dot(positionToEndpoint,lineLength) / dot(lineLength, lineLength);
    distanceBetweenEndpoints = clamp(distanceBetweenEndpoints, 0.0, 1.0);
    return length(positionToEndpoint - lineLength * distanceBetweenEndpoints) - radius;
}

float distanceFromBox(float3 position, float3 center, float3 bounds) {
    float3 q = abs(center - position) - bounds;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)),0.0);
}

float smoothUnion(float distA, float distB, float smoothFactor) {
    float h = clamp(0.5 + (distB - distA) / (smoothFactor * 2.0), 0.0, 1.0 );
    return mix(distB, distA, h) - smoothFactor * h * (1.0-h);
}

float smoothSubtraction(float distA, float distB, float smoothFactor) {
    float h = clamp(0.5 - (distA+distB) / (2.0 * smoothFactor), 0.0, 1.0 );
    return mix(distB, -distA, h) + smoothFactor * h * (1.0 - h);
}

// Returns the distance of the shape that sculpting should begin from when it's reset.
float resetShape(float3 position) {
    return distanceFromBox(position, 0, float3(0.35, 0.35, 0.35));
}

[[kernel]]
void reset(texture3d<float, access::write> voxels [[texture(0)]],
           constant VolumeParams &params [[buffer(1)]],
           uint3 voxelCoords [[thread_position_in_grid]]) {
    
    // Skip out of bounds threads.
    if (any(voxelCoords >= params.dimensions)) { return; }
    
    // Get the position of the current voxel in model space.
    float3 position = params.voxelStartPosition + float3(voxelCoords) * params.voxelSize;
    
    // Get the distance of the current position to the reset shape.
    float distance = resetShape(position);
    
    // Write the distance back to the voxel texture.
    voxels.write(distance, voxelCoords);
}

[[kernel]]
void clearVolume(texture3d<float, access::write> voxels [[texture(0)]],
                 constant VolumeParams &params [[buffer(1)]],
                 uint3 voxelCoords [[thread_position_in_grid]]) {

    // Skip out of bounds threads.
    if (any(voxelCoords >= params.dimensions)) { return; }

    float distance = FLT_MAX;

    // Write the distance back to the voxel texture.
    voxels.write(distance, voxelCoords);
}

[[kernel]]
void sculpt(texture3d<float, access::read> voxelsIn [[texture(0)]],
            texture3d<float, access::write> voxelsOut [[texture(1)]],
            constant VolumeParams &volumeParams [[buffer(2)]],
            constant SculptParams &sculptParams [[buffer(3)]],
            uint3 voxelCoords [[thread_position_in_grid]]) {
    
    // Skip out of bounds threads.
    if (any(voxelCoords >= volumeParams.dimensions)) { return; }
    
    // Read the current voxel value.
    float voxelValue = voxelsIn.read(voxelCoords).r;
    
    // Get the position of the current voxel in model space.
    float3 position = volumeParams.voxelStartPosition + float3(voxelCoords) * volumeParams.voxelSize;
    
    // Get the tool position and radius.
    float3 toolPosition = sculptParams.toolPositionAndRadius.xyz;
    float toolRadius = sculptParams.toolPositionAndRadius.w;
    float3 previousPosition = sculptParams.previousPositionAndHasPosition.xyz;
    bool hasPreviousPosition = sculptParams.previousPositionAndHasPosition.w != 0;

    // Get the distance to the tool.
    float distance;
    if (hasPreviousPosition) {
        distance = distanceFromCappedLine(position, toolPosition, previousPosition, toolRadius);
    } else {
        distance = distanceFromDot(position, toolPosition, toolRadius);
    }

    // Combine the distance of the tool with the distance already in the voxel volume, depending on the mode.
    voxelValue = sculptParams.mode == add ? smoothUnion(distance, voxelValue, 0.01) : smoothSubtraction(distance, voxelValue, 0.01);

    // Write the distance back to the voxel texture.
    voxelsOut.write(voxelValue, voxelCoords);
}
