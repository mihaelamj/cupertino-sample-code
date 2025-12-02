/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This file provides definitions that both the app and the shader use.
*/

#pragma once

#ifdef __METAL_VERSION__
#define NSInteger metal::int32_t
#else
#define constant
#include <Foundation/Foundation.hpp>
#endif

#include <simd/simd.h>

typedef enum BufferIndex : int32_t
{
    AAPLBufferIndexMeshVertices = 0,
    AAPLBufferIndexMeshIndices = 1,
    AAPLBufferIndexMeshInfo = 2,
    AAPLBufferIndexFrameData = 3,
    AAPLBufferViewProjectionMatrix = 4,
    AAPLBufferIndexTransforms = 5,
    AAPLBufferIndexMeshColor = 6,
    AAPLBufferIndexLODChoice = 7
} BufferIndex;

typedef struct AAPLVertex
{
    simd_float4 position;
    simd_float4 normal;
    simd_float2 uv;
} AAPLVertex;

typedef struct AAPLIndexRange
{
    // This is the first offset into the indices array.
    uint32_t startIndex{0};
    // This is one past the first offset into the indices array.
    uint32_t lastIndex{0};
    // This is the index of the first vertex in the vertex array.
    uint32_t startVertexIndex{0};
    uint32_t vertexCount{0};
    uint32_t primitiveCount{0};
} AAPLIndexRange;

typedef struct AAPLMeshInfo
{
    uint16_t numLODs{3};
    uint16_t patchIndex{3};
    simd_float4 color;
    
    uint16_t vertexCount{0};
    
    AAPLIndexRange lod1;
    AAPLIndexRange lod2;
    AAPLIndexRange lod3;
} AAPLMeshInfo;

/// Declare the constant data for the entire frame in this structure.
typedef struct
{
    simd_float4x4 viewProjectionMatrix;
    simd_float4x4 inverseTransform;
} AAPLFrameData;

using AAPLIndexType = uint16_t;

static constexpr constant uint32_t AAPLNumObjectsX = 16;
static constexpr constant uint32_t AAPLNumObjectsY = 8;
static constexpr constant uint32_t AAPLNumObjectsZ = 1;
static constexpr constant uint32_t AAPLNumObjectsXY = AAPLNumObjectsX * AAPLNumObjectsY;
static constexpr constant uint32_t AAPLNumObjectsXYZ = AAPLNumObjectsXY * AAPLNumObjectsZ;

static constexpr constant uint32_t AAPLNumPatchSegmentsX = 8;
static constexpr constant uint32_t AAPLNumPatchSegmentsY = 8;

static constexpr constant uint32_t AAPLMaxMeshletVertexCount = 64;
static constexpr constant uint32_t AAPLMaxPrimitiveCount = 126;

static constexpr constant uint32_t AAPLMaxTotalThreadsPerObjectThreadgroup = 1;
static constexpr constant uint32_t AAPLMaxTotalThreadsPerMeshThreadgroup = AAPLMaxPrimitiveCount;
static constexpr constant uint32_t AAPLMaxThreadgroupsPerMeshGrid = 8;

static constexpr constant uint32_t AAPL_FUNCTION_CONSTANT_TOPOLOGY = 0;
