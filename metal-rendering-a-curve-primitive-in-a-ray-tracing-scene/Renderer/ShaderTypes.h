/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header that contains the types and enumeration constants that the
 Metal shaders and the C/Objective-C source share.
*/

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

#ifndef __METAL_VERSION__
struct packed_float3 {
#ifdef __cplusplus
    packed_float3() = default;
    packed_float3(vector_float3 v) : x(v.x), y(v.y), z(v.z) {}
#endif
    float x;
    float y;
    float z;
};
#endif

struct Camera {
    vector_float3 position;
    vector_float3 right;
    vector_float3 up;
    vector_float3 forward;
};

struct Uniforms {
    unsigned int width;
    unsigned int height;
    unsigned int frameIndex;
    Camera camera;
};

#endif
