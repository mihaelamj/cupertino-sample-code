/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Shaders for custom video composition.
*/

#include <metal_stdlib>

using namespace metal;

// Vertex shader outputs and fragment shader inputs.
struct RasterizerData
{
    float4 position [[position]];
    float4 color;
};

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]], constant float2 *vertices [[buffer(0)]], constant float4& color [[buffer(1)]])
{
    RasterizerData out;
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = (vertices[vertexID] * 2) - 1;
    out.color = color;
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    return in.color;
}
