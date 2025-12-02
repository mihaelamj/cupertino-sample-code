/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Metal shaders the renderer uses to rasterize the thin shards.
*/

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

#import "AAPLShaderTypes.h"
#import "AAPLShaderCommon.h"

/// The vertex shader output and per-fragment input format.
struct RasterizerData
{
    float4 clipSpacePosition [[position]];
    half3 color;
};

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant AAPLVertex *vertexArray [[buffer(AAPLVertexInputIndexVertices)]],
             constant AAPLUniforms &uniforms [[buffer(AAPLVertexInputIndexUniforms)]])

{
    RasterizerData out;
    
    // Rotate the vertex by the rotation angle of the current frame.
    float2 pixelSpacePosition = uniforms.rotationMatrix * vertexArray[vertexID].position.xy * (float2)vertexArray[vertexID].direction;
    
    float2 viewportSize = float2(uniforms.viewportSize);
    
    float zoomFactor = min(viewportSize.x, viewportSize.y) / 300;
    
    // Divide the pixel coordinates by half the size of the viewport to get the clip-space coordinates.
    out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0) * zoomFactor;
    out.clipSpacePosition.z = 0.0;
    out.clipSpacePosition.w = 1.0;
    
    out.color = half3(vertexArray[vertexID].color);
    
    return out;
}

fragment FragData
fragmentShader(RasterizerData in [[stage_in]])
{
    return FragData{half4(in.color, 1.0)};
}

fragment FragData
fragmentShaderHDR(RasterizerData in [[stage_in]])
{
    const half3 tonemappedColor = tonemapByLuminance(in.color.xyz);
    return FragData{half4(tonemappedColor, 1.0)};
}
