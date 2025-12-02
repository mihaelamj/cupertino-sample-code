/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Metal shaders this sample uses.
*/

#include <metal_stdlib>
#include <simd/simd.h>

#import "ShaderTypes.h"

using namespace metal;

struct ColorInOut
{
    float4 position [[ position ]];
    float2 texcoord;
    float3 normal;
};

[[ vertex ]]
ColorInOut vertexShader(const device VertexPosition *vertices [[buffer(BufferIndexMeshPositions)]],
                        const device VertexGenerics *generics [[buffer(BufferIndexMeshGenerics)]],
                        constant ModelConstantsData &constants [[buffer(BufferIndexModelConstants)]],
                        constant FrameData &frameData [[buffer(BufferIndexFrameData)]],
                        uint vid [[ vertex_id ]])
{
    ColorInOut out;
    
    float4 position = float4(vertices[vid].position, 1.0);
    out.position = frameData.projectionViewMatrix * constants.modelMatrix * position;
    out.texcoord = generics[vid].texcoord;
    out.normal = (constants.modelMatrix * float4(generics[vid].normal, 0.0)).xyz;
    
    return out;
}

half3 normalizedNitsToPQ(half3 color)
{
    // The PQ transfer curve. The input 'color' range is 0 to 10,000 nits.
    const half m1 = 0.1593017578125; // 1305.0 / 8192.0
    const half m2 = 78.84375;        // 2523.0 / 32.0
    const half c1 = 0.8359375;       // c3 - c2 - 1.0
    const half c2 = 18.8515625;      // 2413.0 / 128.0
    const half c3 = 18.6875;         // 2392.0 / 128.0
    const float3 Y = saturate(float3(color));
    const float3 Y_m1 = pow(Y, m1);
    const float3 numer = float3(c1 + c2 * Y_m1);
    const float3 denom = float3(1.0h + c3 * Y_m1);
    const float3 result = pow(numer / denom, m2);
    return half3(saturate(result));
}

[[ fragment ]]
half4 fragmentShader(ColorInOut in [[ stage_in ]],
                      constant FrameData & framedata [[buffer(BufferIndexFrameData)]],
                      texture2d<half> colorMap [[texture(TextureIndexColor)]])
{
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);
    
    // Calculate a simple Lambertian diffuse lighting model with a constant ambient term.
    float3 L = framedata.normalizedLightDirection;
    float3 N = normalize(in.normal);
    constexpr float ambientIntensity = 0.1;
    float diffuseIntensity = max(0.0, dot(N, L));
    float lightIntensity = ambientIntensity + diffuseIntensity;
    
    half4 colorSample = colorMap.sample(colorSampler, in.texcoord.xy);
    
    constexpr half linearToNormalizedNits = 100 / 10000.0;
    half3 output = linearToNormalizedNits * colorSample.rgb * lightIntensity;
    
    half3 pq = normalizedNitsToPQ(output);
    return half4(pq, 1.0);
}
