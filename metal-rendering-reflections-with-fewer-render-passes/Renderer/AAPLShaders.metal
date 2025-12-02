/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Metal shaders used for this sample.
*/

#include <metal_stdlib>

using namespace metal;

#include "AAPLShaderTypes.h"

struct Vertex
{
    float3 position  [[attribute(VertexAttributePosition)]];
    float2 texCoord  [[attribute(VertexAttributeTexcoord)]];
    half3  normal    [[attribute(VertexAttributeNormal)]];
    half3  tangent   [[attribute(VertexAttributeTangent)]];
    half3  bitangent [[attribute(VertexAttributeBitangent)]];
};

struct ColorInOut
{
    float4 position [[position]];
    float2 texCoord;

    half3  worldPos;
    half3  tangent;
    half3  bitangent;
    half3  normal;
    uint   face [[render_target_array_index]];
};

// Vertex function
vertex ColorInOut vertexTransform (const Vertex in                               [[ stage_in ]],
                                   const uint   instanceId                       [[ instance_id ]],
                                   const device InstanceParams* instanceParams   [[ buffer     (BufferIndexInstanceParams) ]],
                                   const device ActorParams&    actorParams      [[ buffer (BufferIndexActorParams)    ]],
                                   constant     ViewportParams* viewportParams   [[ buffer (BufferIndexViewportParams) ]] )
{
    ColorInOut out;
    out.texCoord = in.texCoord;

    out.face = instanceParams[instanceId].viewportIndex;

    float4x4 modelMatrix = actorParams.modelMatrix;

    float4 worldPos  = modelMatrix * float4(in.position, 1.0);
    float4 screenPos = viewportParams[out.face].viewProjectionMatrix * worldPos;

    out.worldPos = (half3)worldPos.xyz;
    out.position = screenPos;

    half3x3 normalMatrix = half3x3((half3)modelMatrix[0].xyz,
                                   (half3)modelMatrix[1].xyz,
                                   (half3)modelMatrix[2].xyz);

    out.tangent   = normalMatrix * in.tangent;
    out.bitangent = normalMatrix * in.bitangent;
    out.normal    = normalMatrix * in.normal;

    return out;
}

// Fragment function used to render the temple object in both the
//   reflection pass and the final pass
fragment float4 fragmentLighting (         ColorInOut      in             [[ stage_in ]],
                                  device   ActorParams&    actorParams    [[ buffer (BufferIndexActorParams)    ]],
                                  constant FrameParams &   frameParams    [[ buffer (BufferIndexFrameParams)    ]],
                                  constant ViewportParams* viewportParams [[ buffer (BufferIndexViewportParams) ]],
                                           texture2d<half> baseColorMap   [[ texture (TextureIndexBaseColor)    ]],
                                           texture2d<half> normalMap      [[ texture (TextureIndexNormal)       ]],
                                           texture2d<half> specularMap    [[ texture (TextureIndexSpecular)     ]] )
{
    constexpr sampler linearSampler (mip_filter::linear,
                                     mag_filter::linear,
                                     min_filter::linear);

    const half4 baseColorSample = baseColorMap.sample (linearSampler, in.texCoord.xy);
    half3 normalSampleRaw = normalMap.sample (linearSampler, in.texCoord.xy).xyz;
    // The x and y coordinates in a normal map (red and green channels) are mapped from [-1;1] to [0;255].
    // As the sampler returns a value in [0 ; 1], we need to do :
    normalSampleRaw.xy = normalSampleRaw.xy * 2.0 - 1.0;
    const half3 normalSample = normalize(normalSampleRaw);

    const half  specularSample  = specularMap.sample  (linearSampler, in.texCoord.xy).x*0.5;

    // The per-vertex vectors have been interpolated, thus we need to normalize them again :
    in.tangent   = normalize (in.tangent);
    in.bitangent = normalize (in.bitangent);
    in.normal    = normalize (in.normal);

    half3x3 tangentMatrix = half3x3(in.tangent, in.bitangent, in.normal);

    float3 normal = (float3) (tangentMatrix * normalSample);

    float3 directionalContribution = float3(0);
    float3 specularTerm = float3(0);
    {
        float nDotL = saturate (dot(normal, frameParams.directionalLightInvDirection));

        // The diffuse term is the product of the light color, the surface material
        // reflectance, and the falloff
        float3 diffuseTerm = frameParams.directionalLightColor * nDotL;

        // Apply specular lighting...

        // 1) Calculate the halfway vector between the light direction and the direction they eye is looking
        float3 eyeDir = normalize (viewportParams[in.face].cameraPos - float3(in.worldPos));
        float3 halfwayVector = normalize(frameParams.directionalLightInvDirection + eyeDir);

        // 2) Calculate the reflection amount by evaluating how the halfway vector matches the surface normal
        float reflectionAmount = saturate(dot(normal, halfwayVector));

        // 3) Calculate the specular intensity by powering our reflection amount to our object's
        //    shininess
        float specularIntensity = powr(reflectionAmount, actorParams.materialShininess);

        // 4) Obtain the specular term by multiplying the intensity by our light's color
        specularTerm = frameParams.directionalLightColor * specularIntensity * float(specularSample);

        // The base color sample is actually the diffuse color of the material
        float3 baseColor = float3(baseColorSample.xyz) * actorParams.diffuseMultiplier;

        // The ambient contribution is an approximation for global, indirect lighting, and simply added
        //   to the calculated lit color value below

        // Calculate diffuse contribution from this light : the sum of the diffuse and ambient * albedo
        directionalContribution = baseColor * (diffuseTerm + frameParams.ambientLightColor);
    }

    // Now that we have the contributions our light sources in the scene, we sum them together
    //   to get the fragment's lit color value
    float3 color = specularTerm + directionalContribution;

    // We return the color we just computed and the alpha channel of our baseColorMap for this
    //   fragment's alpha value
    return float4(color, baseColorSample.w);
}

// Fragment function used to render the chrome sphere in the final pass (The only pass the sphere is rendered)
fragment float4 fragmentChromeLighting (         ColorInOut        in             [[ stage_in ]],
                                        constant ViewportParams*   viewportParams [[ buffer (BufferIndexViewportParams) ]],
                                                 texturecube<half> cubeMap        [[ texture (TextureIndexCubeMap)      ]] )
{
    constexpr sampler linearSampler (mip_filter::linear,
                                     mag_filter::linear,
                                     min_filter::linear);

    // The per-vertex vectors have been interpolated, thus we need to normalize them again :
    in.normal = normalize (in.normal);

    float3 eyeDir = normalize (viewportParams[in.face].cameraPos - float3(in.worldPos));

    float similiFresnel = dot ((float3)in.normal, eyeDir);
    similiFresnel = saturate(1.0-similiFresnel);
    similiFresnel = min ( 1.0, similiFresnel * 0.6 + 0.45);

    float3 reflectionDir = reflect (-eyeDir, (float3)in.normal);

    float3 cubeRefl = (float3)cubeMap.sample (linearSampler, reflectionDir).xyz;

    return float4(cubeRefl * similiFresnel, 1.0);
}

fragment float4 fragmentGround (         ColorInOut      in             [[ stage_in ]],
                                constant ViewportParams* viewportParams [[ buffer (BufferIndexViewportParams) ]] )
{
    float onEdge;
    {
        float2 onEdge2d = fract(float2(in.worldPos.xz)/500.f);
        // If onEdge2d is negative, we want 1. Otherwise, we want zero (independent for each axis).
        float2 offset2d = sign(onEdge2d) * -0.5 + 0.5;
        onEdge2d += offset2d;
        onEdge2d = step (0.03, onEdge2d);

        onEdge = min(onEdge2d.x, onEdge2d.y);
    }

    float3 neutralColor = float3 (0.9, 0.9, 0.9);
    float3 edgeColor = neutralColor * 0.2;
    float3 groundColor = mix (edgeColor, neutralColor, onEdge);

    return float4 (groundColor, 1.0);
}
