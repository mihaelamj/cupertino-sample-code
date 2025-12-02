/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Metal shaders used to render skybox
*/

#include <metal_stdlib>

// Include header shared between this Metal shader code and C code executing Metal API commands
#include "AAPLShaderTypes.h"

using namespace metal;

// Per-vertex inputs fed by vertex buffer laid out with MTLVertexDescriptor in Metal API
struct SkyboxVertex
{
    float4 position [[attribute(AAPLVertexAttributePosition)]];
    float3 normal   [[attribute(AAPLVertexAttributeNormal)]];
};

struct SkyboxInOut
{
    float4 position [[position]];
    float3 texcoord;
};

vertex SkyboxInOut skybox_vertex(SkyboxVertex             in        [[ stage_in ]],
                                 constant AAPLFrameData & frameData [[ buffer(AAPLBufferIndexFrameData) ]])
{
    SkyboxInOut out;

    // Add vertex pos to fairy position and project to clip-space
    out.position = frameData.projection_matrix * frameData.sky_modelview_matrix * in.position;

    // Pass position through as texcoord
    out.texcoord = in.normal;

    return out;
}

fragment half4 skybox_fragment(SkyboxInOut        in             [[ stage_in ]],
                               texturecube<float> skybox_texture [[ texture(AAPLTextureIndexBaseColor) ]])
{
    constexpr sampler linearSampler(mip_filter::linear, mag_filter::linear, min_filter::linear);

    float4 color = skybox_texture.sample(linearSampler, in.texcoord);

    return half4(color);
}

