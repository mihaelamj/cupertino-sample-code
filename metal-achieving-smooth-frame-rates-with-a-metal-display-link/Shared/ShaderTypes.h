/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header that contains types and enumeration constants that the Metal shaders and C/Objective-C source share.
*/

#pragma once

#include <simd/simd.h>

enum BufferIndex
{
    BufferIndexMeshPositions  = 0,
    BufferIndexMeshGenerics   = 1,
    BufferIndexModelConstants = 3,
    BufferIndexFrameData      = 4,
};

enum VertexAttribute
{
    VertexAttributePosition  = 0,
    VertexAttributeTexcoord  = 1,
    VertexAttributeNormal    = 2,
};

enum TextureIndex
{
    TextureIndexColor       = 0,
};

struct FrameData
{
    simd_float4x4 projectionMatrix;
    simd_float4x4 viewMatrix;
    simd_float4x4 projectionViewMatrix;
    simd_float3   normalizedLightDirection;
};

/// The data the vertex shader uses to prepare a vertex for rasterization.
struct ModelConstantsData
{
    simd_float4x4 modelMatrix;
};

// Define the attributes so the Metal shader knows how it maps to the vertex descriptor.

#ifdef __METAL_VERSION__
#define VERTEX_ATTRIBUTE_POSITION [[ attribute(VertexAttributePosition) ]]
#define VERTEX_ATTRIBUTE_TEXCOORD [[ attribute(VertexAttributeTexcoord) ]]
#define VERTEX_ATTRIBUTE_NORMAL   [[ attribute(VertexAttributeNormal) ]]
#else
#define VERTEX_ATTRIBUTE_POSITION
#define VERTEX_ATTRIBUTE_TEXCOORD
#define VERTEX_ATTRIBUTE_NORMAL
#endif

/// The attributes that affect a vertex's position.
struct VertexPosition
{
    simd_float3 position VERTEX_ATTRIBUTE_POSITION;
};

/// The generic attributes associated with a vertex.
struct VertexGenerics
{
    simd_float2 texcoord VERTEX_ATTRIBUTE_TEXCOORD;
    simd_float3 normal   VERTEX_ATTRIBUTE_NORMAL;
};

/// The data the vertex shader uses to prepare a vertex for rasterization.
struct MeshConstantData
{
    simd_float4x4 modelMatrix;
};
