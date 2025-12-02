/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header that contains the types and enumeration constants that the Metal shaders and the Objective-C source share.
*/
#pragma once

#include <simd/simd.h>

typedef enum AAPLVertexInputIndex
{
    AAPLVertexInputIndexVertices = 0,
    AAPLVertexInputIndexUniforms = 1,
} AAPLVertexInputIndex;

typedef struct
{
    vector_float2 position;
    vector_float3 color;
    vector_short2 direction;
} AAPLVertex;

typedef struct
{
    matrix_float2x2 rotationMatrix;
    vector_uint2 viewportSize;
} AAPLUniforms;

#define AAPLTileWidth 16
#define AAPLTileHeight 16
#define AAPLTileDataSize 256
#define AAPLThreadgroupBufferSize (AAPLTileWidth * AAPLTileHeight * sizeof(uint32_t))
