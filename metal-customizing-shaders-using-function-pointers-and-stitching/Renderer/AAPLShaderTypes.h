/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header that contains types and enumeration constants shared between Metal shaders and the C/Objective-C source.
*/

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

typedef enum AAPLVertexInputIndex
{
    AAPLVertexInputIndexVertices     = 0,
    AAPLVertexInputIndexViewportSize = 1,
} AAPLVertexInputIndex;

typedef struct
{
    vector_float2 position;
    vector_float2 texCoord;
} AAPLVertex;

typedef struct FractalConfiguration
{
    int iterations;
} FractalConfiguration;

#endif /* ShaderTypes_h */
