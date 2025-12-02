/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header that contains enummerated constants for Metal 2 argument buffers that the Metal shaders and C/ObjC source share.
*/
#ifndef ShaderTypes_Metal2_h
#define ShaderTypes_Metal2_h

#include <simd/simd.h>

// The argument buffer indices the shader and C code share to ensure Metal shader buffer
//   inputs match Metal API set calls.
typedef enum AAPLArgumentBufferID
{
    AAPLArgumentBufferIDExampleTexture,
    AAPLArgumentBufferIDExampleSampler,
    AAPLArgumentBufferIDExampleBuffer,
    AAPLArgumentBufferIDExampleConstant
} AAPLArgumentBufferID;

#endif /* ShaderTypes_Metal2_h */
