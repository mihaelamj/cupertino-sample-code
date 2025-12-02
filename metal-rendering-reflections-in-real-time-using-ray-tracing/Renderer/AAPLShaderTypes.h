/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header that contains types and enumerated constants that the Metal shaders and the C/ObjC source share.
*/
#ifndef AAPLShaderTypes_h
#define AAPLShaderTypes_h

#include <simd/simd.h>

typedef enum AAPLConstantIndex
{
    AAPLConstantIndexRayTracingEnabled
} AAPLConstantIndex;

typedef enum RTReflectionKernelImageIndex
{
    OutImageIndex                   = 0,
    ThinGBufferPositionIndex        = 1,
    ThinGBufferDirectionIndex       = 2,
    IrradianceMapIndex              = 3
} RTReflectionKernelImageIndex;

typedef enum RTReflectionKernelBufferIndex
{
    SceneIndex                      = 0,
    AccelerationStructureIndex      = 1
} RTReflectionKernelBufferIndex;

typedef enum BufferIndex
{
    BufferIndexMeshPositions        = 0,
    BufferIndexMeshGenerics         = 1,
    BufferIndexInstanceTransforms   = 2,
    BufferIndexCameraData           = 3,
    BufferIndexLightData            = 4,
    BufferIndexSubmeshKeypath       = 5
} BufferIndex;

typedef enum VertexAttribute
{
    VertexAttributePosition  = 0,
    VertexAttributeTexcoord  = 1,
} VertexAttribute;

// The attribute index values that the shader and the C code share to ensure Metal
// shader vertex attribute indices match the Metal API vertex descriptor attribute indices.
typedef enum AAPLVertexAttribute
{
    AAPLVertexAttributePosition  = 0,
    AAPLVertexAttributeTexcoord  = 1,
    AAPLVertexAttributeNormal    = 2,
    AAPLVertexAttributeTangent   = 3,
    AAPLVertexAttributeBitangent = 4
} AAPLVertexAttribute;

// The texture index values that the shader and the C code share to ensure
// Metal shader texture indices match indices of Metal API texture set calls.
typedef enum AAPLTextureIndex
{
    AAPLTextureIndexBaseColor        = 0,
    AAPLTextureIndexMetallic         = 1,
    AAPLTextureIndexRoughness        = 2,
    AAPLTextureIndexNormal           = 3,
    AAPLTextureIndexAmbientOcclusion = 4,
    AAPLTextureIndexIrradianceMap    = 5,
    AAPLTextureIndexReflections      = 6,
    AAPLSkyDomeTexture               = 7,
    AAPLMaterialTextureCount = AAPLTextureIndexAmbientOcclusion+1,
} AAPLTextureIndex;

// The buffer index values that the shader and the C code share to
// ensure Metal shader buffer inputs match Metal API buffer set calls.
typedef enum AAPLBufferIndex
{
    AAPLBufferIndexMeshPositions    = 0,
    AAPLBufferIndexMeshGenerics     = 1,
} AAPLBufferIndex;

typedef struct AAPLInstanceTransform
{
    matrix_float4x4 modelViewMatrix;
} AAPLInstanceTransform;

typedef struct AAPLCameraData
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 viewMatrix;
    vector_float3 cameraPosition;
    float metallicBias;
    float roughnessBias;
} AAPLCameraData;

// The structure that the shader and the C code share to ensure the layout of
// data accessed in Metal shaders matches the layout of data set in C code.
typedef struct
{
    // Per Light Properties
    vector_float3 directionalLightInvDirection;
    float lightIntensity;

} AAPLLightData;

typedef struct AAPLSubmeshKeypath
{
    uint32_t instanceID;
    uint32_t submeshID;
} AAPLSubmeshKeypath;

#endif /* ShaderTypes_h */

