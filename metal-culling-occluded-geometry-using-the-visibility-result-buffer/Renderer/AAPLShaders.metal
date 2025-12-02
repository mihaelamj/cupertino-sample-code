/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The source for the app's vertex and fragment shaders.
*/

#include <metal_stdlib>

using namespace metal;

// Include the header the Metal shader code shares with the C code that executes the Metal API commands on the CPU.
#include "AAPLShaderTypes.h"

// Vertex shader outputs and fragment shader inputs.
struct RasterizerData
{
    // The [[position]] attribute of this member indicates that this value
    // is the clip space position of the vertex when this structure is
    // returned from the vertex function.
    float4 position [[position]];

    // Since this member doesn't have a special attribute, the rasterizer
    // interpolates its value with the values of the other triangle vertices
    // and then passes the interpolated value to the fragment shader for each
    // fragment in the triangle.
    float3 color;
    float3 normal;
};

// This lets the app use `setVertexBytes` to set the index of the mesh.
struct MeshIndexData
{
    uint ID;
};

vertex RasterizerData vertexShader(const device vector_float4* positions [[buffer(AAPLBufferIndexPositions)]],
                                   constant AAPLFrameData& frameData [[buffer(AAPLBufferIndexFrameData)]],
                                   constant MeshIndexData& meshIndex [[buffer(AAPLBufferIndexMeshIndex)]],
                                   uint vertexID [[vertex_id]])
{
    RasterizerData out;
    float4 position = positions[vertexID];
    float4 normal   = float4(position.xyz, 0.0);
    out.position = frameData.objects[meshIndex.ID].modelViewProjMatrix * position;
    out.normal = (frameData.objects[meshIndex.ID].modelViewMatrix * normal).xyz;
    out.color = frameData.objects[meshIndex.ID].color;

    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    // Simple lighting (mostly in front).
    half3 L = normalize(half3(1.0, 1.0, 10.0));
    half3 N = (half3)normalize(in.normal);
    half NdotL = max(half(0.2), dot(N, L));
    
    // Add Lambertian shading.
    half3 colorOut = NdotL * half3(in.color.rgb);

    return float4(colorOut.r, colorOut.g, colorOut.b, 1.0);
}
