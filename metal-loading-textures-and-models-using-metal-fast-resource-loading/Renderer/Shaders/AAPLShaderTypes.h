/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header that contains types and enumerated constants that the Metal shaders and the C/ObjC source share.
*/
#import <simd/simd.h>

#define BufferOffsetAlign 16

/// The buffer index values that the shader and the ObjC code share to ensure Metal shader buffer inputs match Metal API buffer set calls.
enum AAPLBufferIndices
{
    AAPLBufferIndexPositions    = 0,
    AAPLBufferIndexNormals      = 1,
    AAPLBufferIndexTexcoords    = 2,
    AAPLBufferIndexObjectParams = 3,
};

/// The constant data buffer that stores the transformation matrices for each object.
typedef struct
{
    matrix_float4x4 modelViewProjectionMatrix;
    matrix_float4x4 modelMatrix;
    matrix_float3x3 normalMatrix;
} AAPLObjectParams;
