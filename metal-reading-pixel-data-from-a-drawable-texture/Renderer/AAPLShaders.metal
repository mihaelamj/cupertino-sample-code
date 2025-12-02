/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Metal shaders used for this sample.
*/

using namespace metal;

#include "AAPLShaderTypes.h"

// Vertex shader outputs and fragment shader inputs.
struct RasterizerData
{
    float4 clipSpacePosition [[position]];

    float4 color;
};

vertex RasterizerData
vertexShader(uint                     vertexID [[ vertex_id ]],
             const device AAPLVertex *vertices [[ buffer(AAPLVertexInputIndexVertices) ]],
             constant vector_uint2   &viewport [[ buffer(AAPLVertexInputIndexViewport) ]])
{
    RasterizerData out;

    // Initialize the output clip space position.
    out.clipSpacePosition = vector_float4(0.0, 0.0, 0.0, 1.0);

    // Specify the input positions in 2D pixel dimensions relative to the
    // upper-left corner of the viewport.
    float2 pixelPosition = vertices[vertexID].position;

    // Use a float viewport to translate input positions from pixel space
    // coordinates into a [-1, 1] coordinate range.
    const vector_float2 floatViewport = vector_float2(viewport);

    // Convert the upper-left relative pixel space positions into normalized clip
    // space positions.
    const vector_float2 topDownClipSpacePosition = (pixelPosition.xy / (floatViewport.xy / 2.0)) - 1.0;

    // Input positions increase downward (top-down) to match Metal blit regions,
    // which are also top-down. Clip space always increases upward, so you negate
    // the y coordinate of `topDownClipSpacePosition` to output a correct
    // `clipSpacePosition` value.
    out.clipSpacePosition.y = -1 * topDownClipSpacePosition.y;
    out.clipSpacePosition.x = topDownClipSpacePosition.x;

    // Pass the input color to the output color.
    out.color = vertices[vertexID].color;

    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    // Return the color set in the vertex shader, which Metal writes to the
    // color render target.
    return in.color;
}

