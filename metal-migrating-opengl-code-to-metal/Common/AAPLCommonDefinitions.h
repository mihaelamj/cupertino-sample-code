/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header that contains types and enumeration constants shared between Metal shaders and C/Objective-C source.
*/
#ifndef ShaderDefinitions_h
#define ShaderDefinitions_h

#include <simd/simd.h>

#define RENDER_REFLECTION 1

#define AAPLReflectionSize ((vector_uint2){512, 512})

// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs match
// Metal API buffer set calls.
typedef enum AAPLBufferIndex
{
    AAPLBufferIndexMeshPositions = 0,
    AAPLBufferIndexMeshGenerics  = 1,
    AAPLBufferIndexMVPMatrix     = 2,
    AAPLBufferIndexUniforms      = 3
} AAPLBufferIndex;

// Attribute index values shared between shader and C code to ensure Metal shader vertex
// attribute indices match Metal API vertex descriptor attribute indices.
typedef enum AAPLVertexAttribute
{
    AAPLVertexAttributePosition  = 0,
    AAPLVertexAttributeTexcoord  = 1,
    AAPLVertexAttributeNormal    = 2,
} AAPLVertexAttribute;

// Texture index values shared between shader and C code to ensure Metal shader texture indices
// match Metal API texture set calls.
typedef enum  AAPLTextureIndex
{
    AAPLTextureIndexBaseColor = 0,
    AAPLNumTextureIndices
}  AAPLTextureIndex;

#ifndef __METAL_VERSION__
typedef struct vector_half4
{
    __fp16 x;
    __fp16 y;
    __fp16 z;
    __fp16 w;
} vector_half4;

typedef struct __attribute__ ((__packed__)) packed_float3
{
    float x;
    float y;
    float z;
} packed_float3;
#endif

typedef struct __attribute__ ((__packed__)) packed_float3x3
{
    packed_float3 columns[3];
} packed_float3x3;

typedef struct __attribute__ ((__packed__)) AAPLVertexGenericData
{
    packed_float2 texcoord;
    packed_float3 normal;
} AAPLVertexGenericData;

typedef struct __attribute__ ((__packed__)) AAPLQuadVertex
{
    vector_float4 position;
    packed_float2 texcoord;
} AAPLQuadVertex;



#endif
