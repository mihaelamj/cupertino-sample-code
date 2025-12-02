/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header containing the types and enumeration constants shared between the Metal shaders and the C/Objective-C source.
*/

#pragma once

#import <simd/simd.h>

#define BufferOffsetAlign 16

/// Texture index values shared between shader and the C code to ensure that Metal shader texture indices match the Metal API texture set calls.
typedef enum AAPLTextureIndices
{
    AAPLTextureIndexBaseColor   = 0
} AAPLTextureIndices;

/// Buffer index values shared between the shader and the C code to ensure the Metal shader buffer inputs match the Metal API buffer set calls.
typedef enum AAPLBufferIndices
{
    AAPLBufferIndexVertices     = 0,
    AAPLBufferIndexSampleParams = 1,
    AAPLBufferIndexResidency    = 2
} AAPLBufferIndices;

typedef struct {
    // Transformations
    matrix_float4x4 modelMatrix;
    matrix_float3x3 normalMatrix;
    matrix_float4x4 viewProjectionMatrix;
    // Sparse Texture Properties
    vector_float2 sparseTextureSizeInTiles;
    vector_float4 quadParamsOffsetAndScale;
} SampleParams;

typedef struct
{
    vector_float4 position;
    vector_float2 texCoord;
} QuadVertex;
