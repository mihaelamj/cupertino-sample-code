/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Metal shaders to cull lights for each tile.
*/
#include <metal_stdlib>

using namespace metal;

// Include header shared between C code and .metal files.
#include "AAPLShaderTypes.h"

// Include header shared between all .metal files.
#include "AAPLShaderCommon.h"

/// Unprojects depth in screen space, giving depth in view space.
static float unproject_depth(constant AAPLFrameData & frameData, float depth)
{
    const float2 depthUnproject = frameData.depthUnproject;
    return depthUnproject.y / (depth - depthUnproject.x);
}

/// Unprojects x and y from screen space to view space, if x and y are at screen z = 1.0.
static float2 screen_to_view_at_z1(constant AAPLFrameData & frameData, ushort2 screen)
{
    const float3 screenToViewSpace = frameData.screenToViewSpace;
    return float2(screen) * float2(screenToViewSpace.x, -screenToViewSpace.x) + float2(screenToViewSpace.y, -screenToViewSpace.z);
}

struct AAPLPlane
{
    float3 normal;
    float offset;
};

static float distance_point_plane(thread const AAPLPlane& plane, float3 point)
{
    return dot( plane.normal, point ) - plane.offset;
}

// Perform per-tile culling for lights and write out list of visible lights into tile memory.

/// Determines the minimum and maximum depth values of all geometry rendered to each tile.
/// Using minimum and maximum depth values makes the culling volume smaller. Because there's no geometry outside the
/// minimum and maximum depth, there's nothing to light outside that range. Any light volume entirely outside the minimum and
/// maximum depth range can be culled.
kernel void create_bins(imageblock<ColorData,imageblock_layout_implicit> imageBlock,
                        constant AAPLFrameData & frameData    [[ buffer(AAPLBufferIndexFrameData) ]],
                        device vector_float4* light_positions [[ buffer(AAPLBufferIndexLightsPosition) ]],
                        threadgroup TileData *tile_data       [[ threadgroup(AAPLThreadgroupBufferIndexTileData) ]],
                        ushort2 thread_local_position         [[ thread_position_in_threadgroup ]],
                        uint thread_linear_id                 [[ thread_index_in_threadgroup ]],
                        uint quad_lane_id                     [[ thread_index_in_quadgroup ]])
{
    ColorData f = imageBlock.read(thread_local_position);
    
    if (thread_linear_id == 0)
    {
        tile_data->minDepth = INFINITY;
        tile_data->maxDepth = 0.0;
    }
    
    // Execute a barrier before getting the minimum and maximum depth values for the entire
    // tile to ensure that all threads in the threadgroup have determined the depth value for
    // their quads first.
    threadgroup_barrier( mem_flags::mem_threadgroup );

    // Determine the minimum and maximum depth in the quad group. Quad groups execute in step, so
    // this kernel can determine the depth values in the quad group without needing to use barriers.

    float minDepth = f.depth;
    minDepth = min( minDepth, quad_shuffle_xor(minDepth, 0x2) );
    minDepth = min( minDepth, quad_shuffle_xor(minDepth, 0x1) );
    
    float maxDepth = f.depth;
    maxDepth = max(maxDepth, quad_shuffle_xor(maxDepth, 0x2));
    maxDepth = max(maxDepth, quad_shuffle_xor(maxDepth, 0x1));

    // For each quad lane, perform the following.
    if (quad_lane_id == 0)
    {
        atomic_fetch_min_explicit((threadgroup atomic_uint *)&tile_data->minDepth, as_type<uint>(minDepth), memory_order_relaxed);
        atomic_fetch_max_explicit((threadgroup atomic_uint *)&tile_data->maxDepth, as_type<uint>(maxDepth), memory_order_relaxed);
    }
}

/// Culls each light's volume against the top, bottom, left, right, near and far planes of the tile.
kernel void cull_lights(imageblock<ColorData,imageblock_layout_implicit> imageBlock,
                        constant AAPLFrameData & frameData    [[ buffer(AAPLBufferIndexFrameData) ]],
                        device vector_float4 *light_positions [[ buffer(AAPLBufferIndexLightsPosition)]],
                        threadgroup int *visible_lights       [[ threadgroup(AAPLThreadgroupBufferIndexLightList)]],
                        threadgroup TileData *tile_data       [[ threadgroup(AAPLThreadgroupBufferIndexTileData)]],
                        ushort2 threadgroup_size              [[ threads_per_threadgroup ]],
                        ushort2 threadgroup_id                [[ threadgroup_position_in_grid ]],
                        uint thread_linear_id                 [[ thread_index_in_threadgroup]])
{
    uint threadgroup_linear_size = threadgroup_size.x*threadgroup_size.y;
    
    // Initialize the tile light count to zero.
    if (thread_linear_id == 0)
    {
        atomic_store_explicit(&tile_data->numLights, 0, memory_order_relaxed);
    }
    threadgroup_barrier( mem_flags::mem_threadgroup );

    // Unproject depth from screen space to view space, where the culling is done.
    float minDepthView = unproject_depth(frameData, tile_data->minDepth);
    float maxDepthView = unproject_depth(frameData, tile_data->maxDepth);
    float2 minTileViewAtZ1 = screen_to_view_at_z1(frameData, threadgroup_id * threadgroup_size);
    float2 maxTileViewAtZ1 = screen_to_view_at_z1(frameData, (threadgroup_id + 1) * threadgroup_size);

    // Calculate the normals of the tile bounding planes.
    AAPLPlane tile_planes[6] = {
        { normalize(float3(1.0, 0.0, -maxTileViewAtZ1.x)), 0.0f }, // right
        { normalize(float3(0.0, 1.0, -minTileViewAtZ1.y)), 0.0f }, // top
        { normalize(float3(-1.0, 0.0, minTileViewAtZ1.x)), 0.0f }, // left
        { normalize(float3(0.0, -1.0, maxTileViewAtZ1.y)), 0.0f }, // bottom
        { float3(0.0, 0.0, -1.0), -minDepthView },                 // near
        { float3(0.0, 0.0, 1.0), maxDepthView }                    // far
    };

    // Create the list of visible lights inside threadgroup memory.
    for (uint baseLightId = 0; baseLightId < AAPLNumLights; baseLightId += threadgroup_linear_size)
    {

        // Get the light ID for the current thread and iteration.
        uint lightId = baseLightId + thread_linear_id;
        if(lightId > AAPLNumLights-1)
        {
            break;
        }

        // Get the light data.
        float3 light_pos_eye_space = light_positions[lightId].xyz;
        float light_radius = light_positions[lightId].w;

        bool visible = true;

        // Cull the light against all six planes.
        for(int j = 0; j < 6; j++)
        {
            if ( distance_point_plane( tile_planes[j], light_pos_eye_space ) > light_radius )
            {
                visible = false; // separating axis found
                break;
            }
        }

        // Perform stream compaction into tile memory.
        // If the light is visible, perform the following.
        if (visible)
        {
            // Increase the count of lights for this tile and get a slot number.
            int slot = atomic_fetch_add_explicit(&tile_data->numLights, 1, memory_order_relaxed);

            // Insert the light ID into the visibile light list for this tile.
            if (slot < AAPLMaxLightsPerTile)
            {
                visible_lights[slot] = (int)lightId;
            }
        }
    }
}
