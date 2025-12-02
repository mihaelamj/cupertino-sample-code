/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The sample's Metal shaders.
*/

#include <metal_stdlib>
using namespace metal;

#import "AAPLShaderTypes.h"

typedef struct
{
    float4  position   [[position]];
    half3   worldNormal;
} ColorInOut;

/// A vertex function that generates a full-screen quad pass.
vertex ColorInOut quadPassVertex(uint vid[[vertex_id]])
{
    ColorInOut out;

    float4 position;
    position.x = (vid == 2) ? 3.0 : -1.0;
    position.y = (vid == 0) ? -3.0 : 1.0;
    position.zw = 1.0;

    out.position = position;
    return out;
}

vertex ColorInOut forwardVertex
(
    uint                      vid          [[vertex_id]],
    device const Vertex      *vertices     [[buffer(AAPLBufferIndexVertices)]],
    device const ActorParams &actorParams  [[buffer(AAPLBufferIndexActorParams)]],
    constant CameraParams    &cameraParams [[buffer(AAPLBufferIndexCameraParams)]]
 )
{
    ColorInOut out;
    out.position = (cameraParams.viewProjectionMatrix * actorParams.modelMatrix * float4(vertices[vid].position.xyz, 1.0f));
    return out;
}

fragment half4 processOpaqueFragment
(
    ColorInOut                in          [[stage_in]],
    device const ActorParams &actorParams [[buffer(AAPLBufferIndexActorParams)]]
)
{
    half4 out;
    out = half4(actorParams.color);
    return out;
}

/// The number of transparent geometry layers that the app stores in image block memory.
/// Each layer consumes tile memory and increases the value of the pipeline's `imageBlockSampleLength` property.
static constexpr constant short kNumLayers = 4;

/// Stores color and depth values of transparent fragments.
/// The `processTransparentFragment` shader adds color values from transparent geometries in
/// ascending depth order.
/// Then, the `blendFragments` shader blends the color values for each fragment in descending
/// depth order after the app draws all the transparent geometry.
struct TransparentFragmentValues
{
    // Store the color of the transparent fragment.
    // Use a packed data type to reduce the size of the explicit ImageBlock.
    rgba8unorm<half4> colors [[raster_order_group(0)]] [kNumLayers];

    // An array of transparent fragment distances from the camera.
    half depths              [[raster_order_group(0)]] [kNumLayers];
};

/// Stores the color values for multiple fragments in image block memory.
/// The `[[imageblock_data]]` attribute tells Metal to store `values` in the GPU's
/// image block memory, which preserves its data for an entire render pass.
struct TransparentFragmentStore
{
    TransparentFragmentValues values [[imageblock_data]];
};

/// Initializes an image block structure to sentinel values.
kernel void initTransparentFragmentStore
(
    imageblock<TransparentFragmentValues, imageblock_layout_explicit> blockData,
    ushort2 localThreadID[[thread_position_in_threadgroup]]
)
{
    threadgroup_imageblock TransparentFragmentValues* fragmentValues = blockData.data(localThreadID);
    for (short i = 0; i < kNumLayers; ++i)
    {
        fragmentValues->colors[i] = half4(0.0h);
        fragmentValues->depths[i] = half(INFINITY);
    }
}

/// Adds transparent fragments into an image block structure in depth order.
fragment TransparentFragmentStore processTransparentFragment
(
    ColorInOut                 in             [[stage_in]],
    device const ActorParams  &actorParams    [[buffer(AAPLBufferIndexActorParams)]],
    TransparentFragmentValues  fragmentValues [[imageblock_data]]
)
{
    TransparentFragmentStore out;
    half4 finalColor = half4(actorParams.color);
    finalColor.xyz *= finalColor.w;

    // Get the fragment distance from the camera.
    half depth = in.position.z / in.position.w;

    // Insert the transparent fragment values in order of depth, discarding
    // the farthest fragments after the `colors` and `depths` are full.
    for (short i = 0; i < kNumLayers; ++i)
    {
        half layerDepth = fragmentValues.depths[i];
        half4 layerColor = fragmentValues.colors[i];

        bool insert = (depth <= layerDepth);
        fragmentValues.colors[i] = insert ? finalColor : layerColor;
        fragmentValues.depths[i] = insert ? depth : layerDepth;

        finalColor = insert ? layerColor : finalColor;
        depth = insert ? layerDepth : depth;
    }
    out.values = fragmentValues;

    return out;
}

/// Blends the opaque fragment in the color attachment with the transparent fragments in the image block
/// structures.
///
/// This shader runs after `processTransparentFragment` inserts the transparent fragments in order of depth from back to front.
fragment half4 blendFragments
(
    TransparentFragmentValues fragmentValues     [[imageblock_data]],
    half4                     forwardOpaqueColor [[color(AAPLRenderTargetColor), raster_order_group(0)]]
 )
{
    half4 out;

    // Start with the opaque fragment from the color attachment.
    out.xyz = forwardOpaqueColor.xyz;

    // Blend the transparent fragments in the image block from the back to front,
    // which is equivalent to the farthest layer moving toward the nearest layer.
    for (short i = kNumLayers - 1; i >= 0; --i)
    {
        half4 layerColor = fragmentValues.colors[i];
        out.xyz = layerColor.xyz + (1.0h - layerColor.w) * out.xyz;
    }

    out.w = 1.0;

    return out;
}
