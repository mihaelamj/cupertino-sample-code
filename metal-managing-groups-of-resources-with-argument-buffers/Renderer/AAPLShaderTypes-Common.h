/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header that contains types and enummerated constants that the Metal shaders and C/ObjC source share.
*/
#ifndef ShaderTypes_Common_h
#define ShaderTypes_Common_h

#include <simd/simd.h>

// The buffer index values that the shader and C code share to ensure Metal
//   vertex shader buffer inputs match Metal API set calls.
typedef enum AAPLVertexBufferIndex
{
    AAPLVertexBufferIndexVertices = 0,
} AAPLVertexBufferIndex;

// The buffer index values that the shader and C code share to ensure Metal
//   fragment shader buffer inputs match Metal API set calls.
typedef enum AAPLFragmentBufferIndex
{
    AAPLFragmentBufferIndexArguments = 0,
} AAPLFragmentBufferIndex;

//  Defines the layout of each vertex in the array of vertices that functions
//     as an input to the Metal vertex shader.
typedef struct AAPLVertex {
    vector_float2 position;
    vector_float2 texCoord;
    vector_float4 color;
} AAPLVertex;

#endif /* ShaderTypes_Common_h */
