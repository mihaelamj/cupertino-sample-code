/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Metal shaders used to resolve MSAA on tile.
*/

#include <metal_stdlib>
using namespace metal;

#import "AAPLShaderCommon.h"

/// A tile kernel for a custom MSAA resolve that calculates the average color for all the samples.
///
/// Apple A11 and later GPU devices keep track of the sample colors and the number of samples each color applies to.
kernel void
averageResolveTileKernel(imageblock<FragData> img_blk_colors,
                         ushort2 tid [[thread_position_in_threadgroup]])
{
    const ushort pixelColorCount = img_blk_colors.get_num_colors(tid);
    
    half4 resolved_color = half4(0);
    
    for (int i = 0; i < pixelColorCount; ++i)
    {
        // To access all (up to four) samples in the pixel sequentially, run the loop up to four times, and read
        // each sample color with imageblock_data_rate:sample.
        // Fortunately, Apple GPUs can keep track of unique color samples at each pixel. Here, we instead
        // read unique colors with `imageblock_dat_rate::color`, so if there aren't as many unique colors at
        // the current pixel, this iteration can finish earlier.
        const half4 color = img_blk_colors.read(tid, i, imageblock_data_rate::color).resolvedColor;
        
        // Color coverage information is stored as a bit mask. Use `popcount` to get the occurrences of the color.
        // Check the Metal Shading Language Specification for more information.
        const ushort sampleColorCount = popcount(img_blk_colors.get_color_coverage_mask(tid, i));
        
        resolved_color += color * sampleColorCount;
    }
    
    resolved_color /= img_blk_colors.get_num_samples();
    
    const ushort output_sample_mask = 0xF;
    
    img_blk_colors.write(FragData{resolved_color}, tid, output_sample_mask);
}

/// A tile kernel for a custom MSAA resolve that applies tone-mapping to HDR color samples before it calculates the average color for the pixel.
kernel void
hdrResolveTileKernel(imageblock<FragData> img_blk_colors,
                     ushort2 tid [[thread_position_in_threadgroup]])
{
    
    const ushort pixelColorCount = img_blk_colors.get_num_colors(tid);
    
    half4 resolved_color = half4(0);
    
    for (ushort i = 0; i < pixelColorCount; ++i)
    {
        const half4 color = img_blk_colors.read(tid, i, imageblock_data_rate::color).resolvedColor;
        
        const ushort sampleColorCount = popcount(img_blk_colors.get_color_coverage_mask(tid, i));
        
        const half3 tonemappedColor = tonemapByLuminance(color.xyz);
        
        resolved_color += half4(tonemappedColor, 1) * sampleColorCount;
    }
    
    resolved_color /= img_blk_colors.get_num_samples();
    
    const ushort output_sample_mask = 0xF;
    
    img_blk_colors.write(FragData{resolved_color}, tid, output_sample_mask);
}
