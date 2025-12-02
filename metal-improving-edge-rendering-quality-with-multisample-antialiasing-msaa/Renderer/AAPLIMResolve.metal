/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Metal shaders used to resolve MSAA on a compute pass.
*/

#include <metal_stdlib>
using namespace metal;

#import "AAPLShaderCommon.h"

/// A custom resolve kernel that averages color at all sample points.
kernel void
averageResolveKernel(texture2d_ms<float, access::read> multisampledTexture [[texture(0)]],
                     texture2d<float, access::write> resolvedTexture [[texture(1)]],
                     uint2 gid [[thread_position_in_grid]])
{
    const uint count = multisampledTexture.get_num_samples();
    
    float4 resolved_color = 0;
    
    for (uint i = 0; i < count; ++i)
    {
        resolved_color += multisampledTexture.read(gid, i);
    }
    
    resolved_color /= count;
    
    resolvedTexture.write(resolved_color, gid);
}

/// A compute kernel for a custom MSAA resolve that applies tone-mapping to HDR color samples,
/// before resolving the average color at this pixel.
kernel void
hdrResolveKernel(texture2d_ms<half, access::read> multisampledTexture [[texture(0)]],
                 texture2d<half, access::write> resolvedTexture [[texture(1)]],
                 uint2 gid [[thread_position_in_grid]])
{
    const uint count = multisampledTexture.get_num_samples();
    
    half4 resolved_color = 0;
    
    for (uint i = 0; i < count; ++i)
    {
        const half4 sampleColor = multisampledTexture.read(gid, i);
        
        const half3 tonemappedColor = tonemapByLuminance(sampleColor.xyz);
        
        resolved_color += half4(tonemappedColor, 1);
    }
    
    resolved_color /= count;
    
    resolvedTexture.write(resolved_color, gid);
}
