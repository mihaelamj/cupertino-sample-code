/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Metal shader file containing the tone-mapping function and the full-screen quad vertex and fragment functions.
*/

#include <metal_stdlib>
using namespace metal;

#import "AAPLShaderCommon.h"

/// Tone-maps an input color by calculating its Rec. 709 luminance and applying a simple tone-mapping operator.
half3 tonemapByLuminance(half3 inColor)
{
    const half3 kRec709Luma(0.2126h, 0.7152h, 0.0722h);
    
    const half luminance = dot(inColor, kRec709Luma);
    
    return inColor / (1 + luminance);
}

// MARK: - Shaders to copy a resolved texture to the render target.

/// The normalized device coordinates (NDC) for two triangles that form a full-screen quad.
constant float2 quadVertices[] = {
    float2(-1, -1),
    float2(-1,  1),
    float2( 1,  1),
    float2(-1, -1),
    float2( 1,  1),
    float2( 1, -1)
};

/// A vertex format for drawing a full-screen quad.
struct CompositionVertexOut {
    float4 position [[position]];
    float2 uv;
};

/// Outputs the normalized device coordinates (NDC) to render a full-screen quad based on the vertex ID.
vertex CompositionVertexOut
compositeVertexShader(unsigned short vid [[vertex_id]])
{
    const float2 position = quadVertices[vid];
    
    CompositionVertexOut out;
    
    out.position = float4(position, 0, 1);
    out.position.y *= -1;
    out.uv = position * 0.5f + 0.5f;
    
    return out;
}

/// Copies the input resolve texture to the output.
fragment half4
compositeFragmentShader(CompositionVertexOut in [[stage_in]],
                        texture2d<half> resolvedTexture)
{
    constexpr sampler sam(min_filter::nearest, mag_filter::nearest, mip_filter::none);
    
    const half3 color = resolvedTexture.sample(sam, in.uv).xyz;
    
    return half4(color, 1.0f);
}
