/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Defines the types and constants that the Metal shaders and C/ObjC source share.
*/

#ifndef AAPLShaderTypes_h
#define AAPLShaderTypes_h
#import <simd/simd.h>

// `[MTLRenderCommandEncoder setVertexBuffer:offset:atIndex]` requires that buffer offsets be
// 256 bytes aligned for buffers using the constant address space and 16 bytes aligned for buffers
// using the device address space. The sample uses the device address space for the `actorParams`
// parameter of the shaders and uses the `set[Vertex|Framgment:offset:` methods to iterate
// through `ActorParams` structures. So it aligns each element of `_actorParamsBuffers` by 16 bytes.
#define BufferOffsetAlign 16

// Buffer index values shared between the shader and C code to ensure that the Metal shader buffer inputs match
// the Metal API buffer set calls.
typedef enum AAPLBufferIndices
{
    AAPLBufferIndexVertices         = 1,
    AAPLBufferIndexActorParams      = 2,
    AAPLBufferIndexCameraParams     = 3
} AAPLBufferIndices;

// RenderTarget index values shared between the shader and C code to ensure that the Metal shader render target
// index matches the Metal API pipeline and render pass.
typedef enum AAPLRenderTargetIndices
{
    AAPLRenderTargetColor           = 0,
} AAPLRenderTargetIndices;

// Structures shared between the shader and C code to ensure that the layout of per frame data
// accessed in Metal shaders matches the layout of the data set in C code.
// Data constant across all threads, vertices, and fragments.

typedef struct __attribute__((aligned(BufferOffsetAlign)))
{
    matrix_float4x4 modelMatrix;
    vector_float4   color;
} ActorParams;

typedef struct
{
    vector_float4 position;
} Vertex;

typedef struct
{
    vector_float3   cameraPos;
    matrix_float4x4 viewProjectionMatrix;
} CameraParams;

#endif /* AAPLShaderTypes_h */
