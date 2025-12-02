/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Metal shaders to use for this sample.
*/

#include <metal_stdlib>
#include "AAPLShaderTypes.h"
using namespace metal;

struct FragmentIn
{
    float4 position [[position]];
    float3 normal;
    float2 texcoord;
};

vertex FragmentIn
vertexShader(const device float3* positions    [[buffer(AAPLBufferIndexPositions)]],
             const device float3* normals      [[buffer(AAPLBufferIndexNormals)]],
             const device float2* texcoords    [[buffer(AAPLBufferIndexTexcoords)]],
             constant AAPLObjectParams& object [[buffer(AAPLBufferIndexObjectParams)]],
             uint vertexID                     [[vertex_id]])
{
    FragmentIn out;
    float4 position = float4(positions[vertexID], 1.0);
    out.position = object.modelViewProjectionMatrix * position;
    out.normal = normalize(object.normalMatrix * normals[vertexID]);
    out.texcoord = texcoords[vertexID];
    return out;
}

fragment half4
fragmentShader(FragmentIn      in           [[stage_in]],
               texture2d<half> colorTexture [[texture(0)]])
{
    constexpr sampler linearSampler(mip_filter::linear,
                                    mag_filter::linear,
                                    min_filter::linear,
                                    s_address::repeat,
                                    t_address::repeat,
                                    max_anisotropy(16));
    // Sample the texture map.
    half3 texel = colorTexture.sample(linearSampler, in.texcoord).rgb;

    // Initialize the lighting vectors.
    float3 N = normalize(in.normal);
    float3 L = normalize(float3(1, 4, -2));
    float3 V = float3(0, 0, -1);
    float3 H = normalize(L + V);
    
    // Apply a nonphotorealistic adjustment to the dot product to improve contrast.
    float NdotL = saturate(0.5 + 0.5 * dot(N, L));
    float NdotH = saturate(0.5 + 0.5 * dot(N, H));
    NdotL = pow(NdotL, 3.0);

    // Calculate a shiny specular highlight.
    float highlight = 0;
    constexpr float F0 = 0.05;
    float F = F0;
    if (NdotH > 0.0)
    {
        F = F0 + (1 - F0) * pow(1 - NdotH, 5.0);
        highlight = 100 * F * pow(NdotH, 900);
    }

    // For visualization ambience, add a bit of tint from the normal color.
    half3 rgb = (half3)(0.5 * in.normal + 0.5);

    // Give a little bit of ambient reflection by clamping the lower bound of NdotL to the Fresnel.
    half3 color = saturate(highlight + NdotL * mix(texel, rgb, F));
    return half4(color, 1);
}
