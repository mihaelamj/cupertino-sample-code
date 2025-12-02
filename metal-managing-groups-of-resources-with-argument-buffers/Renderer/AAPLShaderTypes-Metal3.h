/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header that contains types for Metal 2 argument buffers that the Metal shaders and C/ObjC source share.
*/
#ifndef ShaderTypes_Metal3_h
#define ShaderTypes_Metal3_h

#include <simd/simd.h>

#ifndef __METAL_VERSION__

template<typename T>
class texture2d : public MTLResourceID {
public:
    texture2d(MTLResourceID v) : MTLResourceID(v) {}
};

class sampler : public MTLResourceID {
public:
    sampler(MTLResourceID v) : MTLResourceID(v) {}
};

typedef uint16_t half;

#define DEVICE

#else

#define DEVICE device

#endif


struct FragmentShaderArguments {
    texture2d<half>  exampleTexture;
    sampler          exampleSampler;
    DEVICE float    *exampleBuffer;
    uint32_t         exampleConstant;
};

#endif /* ShaderTypes_Metal3_h */
