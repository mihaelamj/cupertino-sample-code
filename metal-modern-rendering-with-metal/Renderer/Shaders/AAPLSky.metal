/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Shaders for rendering the skybox.
*/

#import "AAPLShaderCommon.h"

//------------------------------------------------------------------------------

constant bool gUseRasterizationRate [[function_constant(AAPLFunctionConstIndexRasterizationRate)]];

//------------------------------------------------------------------------------

// Skybox shader for forward rendering.
fragment xhalf4 skyboxShader(AAPLSimpleTexVertexOut in                      [[ stage_in ]],
                             constant AAPLFrameConstants & frameData        [[ buffer(AAPLBufferIndexFrameData) ]],
                             constant AAPLCameraParams & cameraParams       [[ buffer(AAPLBufferIndexCameraParams) ]],
                             constant rasterization_rate_map_data * rrData  [[ buffer(AAPLBufferIndexRasterizationRateMap), function_constant(gUseRasterizationRate) ]],
                             constant AAPLGlobalTextures & globalTextures   [[ buffer(AAPLBufferIndexFragmentGlobalTextures) ]]
                             )
{
    xhalf3 result = (xhalf3)frameData.skyColor;

    float2 screenUV = in.texCoord.xy;
#if SUPPORT_RASTERIZATION_RATE
    if (gUseRasterizationRate)
    {
        // Currently drawing inside compressed space, so must fix up screen space.
        rasterization_rate_map_decoder decoder(*rrData);
        screenUV = decoder.map_physical_to_screen_coordinates(screenUV * frameData.physicalSize) * frameData.invScreenSize;
    }
#endif

#if USE_SCATTERING_VOLUME
    float linearDepth = linearizeDepth(cameraParams, 1.0f);
    xhalf4 scatteringSample;
    {
        constexpr sampler linearSampler(mip_filter::linear, mag_filter::linear, min_filter::linear, address::clamp_to_edge);

        float scatterDepth = zToScatterDepth(linearDepth);
        scatterDepth = saturate(scatterDepth);

        scatteringSample = globalTextures.scattering.sample(linearSampler, float3(screenUV, scatterDepth));

        result = result * scatteringSample.a + scatteringSample.rgb;
    }
#endif

    return xhalf4(result, 0.0f);
}
