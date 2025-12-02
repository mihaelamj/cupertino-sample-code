/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Metal shaders used for this sample.
*/

#include <metal_stdlib>
#include "AAPLUserDylib.h"
// Shared types between CPU and Metal shader code.
#include "AAPLShaderTypes.h"

using namespace metal;

#pragma mark Function Pointers

[[visible]] float4 colorInside(int iteration, float distance)
{
    return AAPLUserDylib::calculateColorInside(iteration, distance);
}

[[visible]] float4 colorEscaped(int iteration, float distance)
{
    return AAPLUserDylib::calculateColorEscaped(iteration, distance);
}

#pragma mark Function Stitching

[[stitchable]] float2 add(float2 a, float2 b)
{
    return a + b;
}

[[stitchable]] float2 subtract(float2 a, float2 b)
{
    return a - b;
}

[[stitchable]] float2 multiply(float2x2 a, float2 b)
{
    return a * b;
}

[[stitchable]] float negate(float a)
{
    return -a;
}

[[stitchable]] float get_x_component(float2 a)
{
    return a.x;
}

[[stitchable]] float get_y_component(float2 a)
{
    return a.y;
}

[[stitchable]] float2x2 init_A(float x, float y, float z, float w)
{
    return float2x2(x, y, z, w);
}

[[visible]] float2 calculate_Z(float2 z, float2 c);

#pragma mark Stage Shaders

struct RasterizerData
{
    float4 position [[position]];
    float2 texCoord;
};

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant AAPLVertex *vertices [[buffer(AAPLVertexInputIndexVertices)]],
             constant vector_uint2 *viewportSizePointer [[buffer(AAPLVertexInputIndexViewportSize)]])
{
    RasterizerData out;
    
    // Index into the array of positions to get the current vertex.
    // The positions are specified in pixel dimensions. A value of 100
    // is 100 pixels from the origin.
    float2 pixelSpacePosition = vertices[vertexID].position.xy;
    
    // Get the viewport size and cast to float.
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);
    
    // To convert from positions in pixel space to positions in clip-space,
    //  divide the pixel coordinates by half the size of the viewport.
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition / (viewportSize / 2.0);
    
    out.texCoord = vertices[vertexID].texCoord;
    
    return out;
}

/// Fragment shader that renderers a Mandelbrot fractal with either "Normal" or "Debug" visualization.
fragment float4
mandlebrotFragment(RasterizerData vertexOut [[stage_in]],
                   constant FractalConfiguration& configuration [[buffer(0)]],
                   visible_function_table<float4 (int, float)> colorization[[buffer(1)]])
{
    uint escaped = 0;
    float2 z = 0;
    float2 c = vertexOut.texCoord;
    int j = configuration.iterations;
    int iterations = 0;
    for(; iterations < j; iterations++)
    {
        // Calculate z with a stitched function.
        z = calculate_Z(z, c);
        if(length(z) > 2.0)
        {
            escaped = 1;
            break;
        }
    }
    
    // Select the colorization function with the computed "escaped" index.
    return colorization[escaped](iterations, length(z));
}
