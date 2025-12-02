/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Metal shaders used by the app.
*/

#include <metal_stdlib>
#include "AAPLShaderTypes.h"

using namespace metal;

struct FragmentIn
{
    float4 position [[position]];
    float2 texCoord;
};

/// Return the minimum mipmap level available in the sparse texture.
float getResidencyBufferMipmap(const device char* residencyBuffer,
                               float2 sparseTextureSizeInTiles,
                               float2 texCoord)
{
    // Transform the UV coordinate from a pixel coordinate to a tile coordinate.
    ushort readX = (ushort) (clamp(texCoord.x, 0.f, 0.99f) * sparseTextureSizeInTiles.x);
    ushort readY = (ushort) (clamp(texCoord.y, 0.f, 0.99f) * sparseTextureSizeInTiles.y);
    ushort index = readX + (readY * (ushort)sparseTextureSizeInTiles.x);
    ushort val = residencyBuffer[index];
    return (float)val;
}

/// Sample the sparse texture and return a lower mipmap level if the tile isn't resident.
half4 sampleSparseTexture(texture2d<half, access::sample> sparseTexture,
                          float2 texCoord,
                          float2 sparseTextureSizeInTiles,
                          const device char* residencyBuffer)
{
    constexpr sampler linearSampler(mip_filter::linear,
                                    mag_filter::linear,
                                    min_filter::linear,
                                    s_address::clamp_to_edge,
                                    t_address::clamp_to_edge);
    // The `sparse_sample` function returns a `sparse_color` type to safely sample the sparse texture's region.
    sparse_color<half4> sparseColor = sparseTexture.sparse_sample(linearSampler, texCoord);
    half4 baseColor = half4(0.h);
    // The `resident` function returns `true` if the sampled region is mapped.
    if (sparseColor.resident())
    {
        baseColor = sparseColor.value();
    }
    else
    {
        float residentBufferMipmap = getResidencyBufferMipmap(residencyBuffer, sparseTextureSizeInTiles, texCoord);
        // `min_lod_clamp` restricts the minimum mipmap level that the shader can sample.
        baseColor = sparseTexture.sample(linearSampler, texCoord, min_lod_clamp(residentBufferMipmap));
    }
    return baseColor;
}

fragment half4 forwardFragment(FragmentIn in [[stage_in]],
                               texture2d<half, access::sample> baseColorTexture [[texture(AAPLTextureIndexBaseColor)]],
                               constant SampleParams& sample                    [[buffer(AAPLBufferIndexSampleParams)]])
{
    constexpr sampler linearSampler(mip_filter::linear,
                                    mag_filter::linear,
                                    min_filter::linear,
                                    s_address::repeat,
                                    t_address::repeat);
    half4 baseColor = baseColorTexture.sample(linearSampler, in.texCoord);
    return baseColor;
}

vertex FragmentIn forwardPlaneVertex(const device QuadVertex* vertices [[buffer(AAPLBufferIndexVertices)]],
                                     constant SampleParams& sample     [[buffer(AAPLBufferIndexSampleParams)]],
                                     uint vertexID [[vertex_id]])
{
    FragmentIn out;
    out.position = sample.viewProjectionMatrix * sample.modelMatrix * vertices[vertexID].position;
    out.texCoord = vertices[vertexID].texCoord;
    return out;
}

fragment half4 forwardWithSparseTextureFragment(FragmentIn in [[stage_in]],
                                                texture2d<half, access::sample> baseColorTexture [[texture(AAPLTextureIndexBaseColor)]],
                                                constant SampleParams& sample                    [[buffer(AAPLBufferIndexSampleParams)]],
                                                const device char* baseColorResidencyBuffer      [[buffer(AAPLBufferIndexResidency)]])
{
    half4 baseColor = sampleSparseTexture (baseColorTexture, in.texCoord, sample.sparseTextureSizeInTiles, baseColorResidencyBuffer);
    return baseColor;
}


// The following shader code is used when DEBUG_SPARSE_TEXTURE is 1.
#if 1

vertex FragmentIn debugSparseTextureQuadVertex (const device QuadVertex* vertices [[buffer(AAPLBufferIndexVertices)]],
                                                constant SampleParams& sample     [[buffer(AAPLBufferIndexSampleParams)]],
                                                uint vertexID [[vertex_id]])
{
    FragmentIn out;
    out.position = (vertices[vertexID].position * sample.quadParamsOffsetAndScale.w);
    out.position.xy += sample.quadParamsOffsetAndScale.xy;
    out.position.zw = float2(0.f, 1.f);
    out.texCoord = vertices[vertexID].texCoord;
    return out;
}

fragment half4 debugSparseTextureQuadFragment (FragmentIn in [[stage_in]],
                                               constant SampleParams& sample      [[buffer(AAPLBufferIndexSampleParams)]],
                                               const device char* residencyBuffer [[buffer(AAPLBufferIndexResidency)]])
{
    float residentBufferMipmap = getResidencyBufferMipmap(residencyBuffer, sample.sparseTextureSizeInTiles, in.texCoord);
    half4 finalColor = half4(1.h);
    const half constOffset = 0.5h;
    half offsetVal = residentBufferMipmap * constOffset;
    
    if (residentBufferMipmap > 0.f)
    {
        finalColor.z -= offsetVal;
    }
    
    if (residentBufferMipmap > 2.f)
    {
        offsetVal -= constOffset * 2.h;
        finalColor.y -= offsetVal;
    }
    
    if (residentBufferMipmap > 4.f)
    {
        offsetVal -= constOffset * 2.h;
        finalColor.x -= offsetVal;
    }
    
    if (residentBufferMipmap > 5.f)
    {
        finalColor = half4(0.5h, 0.h, 0.5h, 1.h);
    }
    
    return finalColor;
}

#endif
