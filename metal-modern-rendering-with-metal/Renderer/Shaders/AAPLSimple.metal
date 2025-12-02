/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the simple rendering shaders.
*/

#import "AAPLShaderCommon.h"
#import "AAPLCullingShared.h"

//------------------------------------------------------------------------------

constant bool gUseRasterizationRate [[function_constant(AAPLFunctionConstIndexRasterizationRate)]];

//------------------------------------------------------------------------------

// Vertex shader for rendering a full screen quad.
vertex AAPLSimpleTexVertexOut FSQuadVertexShader(uint vid [[vertex_id]])
{
    AAPLSimpleTexVertexOut out;
    out.texCoord = float2((vid << 1) & 2, vid & 2);
    out.position = float4(out.texCoord * float2(2.0f, -2.0f) + float2(-1.0f, 1.0f), 1.0f, 1.0f);
    return out;
}

// Simple vertex shader for transforming the array of provided vertices.
vertex AAPLSimpleVertexOut vertexSimpleShader(constant float4x4 & wvpMatrix   [[ buffer(AAPLBufferIndexCameraParams) ]],
                                              const device float3 * positions [[ buffer(AAPLBufferIndexVertexMeshPositions) ]],
                                              uint vid [[vertex_id]])
{
    AAPLSimpleVertexOut out;
    out.position = wvpMatrix * float4(positions[vid], 1.0f);
    return out;
}

// Simple fragment shader for outputting a color.
fragment float4 fragmentSimpleShader(constant float4 & color [[ buffer(AAPLBufferIndexFragmentMaterial) ]])
{
    return color;
}

// Simple fragment shader for outputting a texture sample.
fragment float4 fragmentSimpleTexShader(AAPLSimpleTexVertexOut in [[stage_in]],
                                        texture2d<float, access::sample> tex [[texture(0)]])
{
    constexpr sampler sam(mip_filter::linear, mag_filter::linear, min_filter::linear, address::clamp_to_edge);
    return tex.sample(sam, in.texCoord);
}

#if SUPPORT_RASTERIZATION_RATE

// Simple shader that can be used to compose shader-depth-tested primites onto a post-resolved
// render-target.  In this case, the depth-buffer is of the pre-resolve size, so we cannot attach
// both to the renderpass.  Manual depth-test done in the shader instead.
vertex AAPLSimpleTexVertexOut rrVertexSimpleShader(constant float4x4 & wvpMatrix           [[ buffer(AAPLBufferIndexCameraParams) ]],
                                                   constant AAPLFrameConstants & frameData [[ buffer(AAPLBufferIndexFrameData) ]],
                                                   const device float3 * positions         [[ buffer(AAPLBufferIndexVertexMeshPositions) ]],
                                                   uint vid                                [[ vertex_id ]])
{
    AAPLSimpleTexVertexOut out;
    out.position = wvpMatrix * float4(positions[vid], 1.0f);

    float2 clip = out.position.xy / out.position.w;
    float2 screenCoord = clip * 0.5f + 0.5f;
    float2 screenPos = screenCoord * frameData.screenSize;
    out.texCoord = screenPos;

    return out;
}

// Simple fragment shader for outputting a color.
fragment float4 rrFragmentSimpleShader(AAPLSimpleTexVertexOut in                     [[ stage_in ]],
                                       constant float4 & color                       [[ buffer(AAPLBufferIndexFragmentMaterial) ]],
                                       constant rasterization_rate_map_data * rrData [[ buffer(AAPLBufferIndexRasterizationRateMap) ]],
                                       texture2d<float, access::sample> depth        [[ texture(0) ]])
{
    rasterization_rate_map_decoder decoder(*rrData);
    float2 screenPos = in.texCoord;
    float2 physPos = decoder.map_screen_to_physical_coordinates(screenPos);

    constexpr sampler nearest = sampler(filter::nearest, coord::pixel);
    float sceneDepth = depth.sample(nearest, physPos).r;
    float primitiveDepth = in.position.z;
    if (sceneDepth > primitiveDepth)
    {
        discard_fragment();
    }

    return color;
}

#endif

//------------------------------------------------------------------------------

fragment void dummyFragmentShader() { return; }
