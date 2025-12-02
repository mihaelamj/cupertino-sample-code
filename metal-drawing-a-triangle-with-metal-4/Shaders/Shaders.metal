/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's source code for its Metal shaders.
*/

#include <metal_stdlib>

using namespace metal;

// Include the communal types that both the Metal shader code and the app's
// C/ObjC code share.
#include "ShaderTypes.h"

/// A type that stores the vertex shader's output and serves as an input to the
/// fragment shader.
struct RasterizerData
{
    /// A 4D position in clip space from a vertex shader function.
    ///
    /// The `[[position]]` attribute indicates that the position is the vertex's
    /// clip-space position.
    float4 position [[position]];

    /// A color value, either for a vertex as an output from a vertex shader,
    /// or for a fragment as input to a fragment shader.
    ///
    /// As an input to a fragment shader, the rasterizer interpolates the color
    /// values between the triangle's vertices for each fragment because this
    /// member doesn't have a special attribute.
    float4 color;
};

/// A vertex shader that converts each input vertex from pixel coordinates to
/// clip-space coordinates.
///
/// The vertex shader doesn't modify the color values.
vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant VertexData *vertexData [[buffer(InputBufferIndexForVertexData)]],
             constant simd_uint2 *viewportSizePointer [[buffer(InputBufferIndexForViewportSize)]])
{
    RasterizerData out;

    // Retrieve the 2D position in pixel coordinates.
    simd_float2 pixelSpacePosition = vertexData[vertexID].position.xy;

    // Retrieve the viewport's size by casting it to a 2D float value.
    simd_float2 viewportSize = simd_float2(*viewportSizePointer);

    // Convert the position in pixel coordinates to clip-space by dividing the
    // pixel's coordinates by half the size of the viewport.
    out.position.xy = pixelSpacePosition / (viewportSize / 2.0);
    out.position.z = 0.0;
    out.position.w = 1.0;

    // Pass the input color directly to the rasterizer.
    out.color = vertexData[vertexID].color;

    return out;
}

/// A basic fragment shader that returns the color data from the rasterizer
/// without modifying it.
fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    // Return the color the rasterizer interpolates between the triangle's
    // three vertex colors.
    return in.color;
}
