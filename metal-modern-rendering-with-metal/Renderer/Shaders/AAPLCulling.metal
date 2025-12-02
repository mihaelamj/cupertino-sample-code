/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Kernel for culling Mesh chunks and creating an ICB rendering only visible objects.
*/

#import "AAPLShaderCommon.h"
#import "AAPLCullingShared.h"

// Toggled to enable/disable occlusion culling.
constant bool gUseOcclusionCulling  [[function_constant(AAPLFunctionConstIndexUseOcclusionCulling)]];

// Toggled for objects with alpha mask during depth only render command encoding.
constant bool gUseAlphaMask         [[function_constant(AAPLFunctionConstIndexEncodeAlphaMask)]];

// Toggled for encoding depth only render pass render commands.
constant bool gEncodeToDepthOnly    [[function_constant(AAPLFunctionConstIndexEncodeToDepthOnly)]];

// Toggled for encoding main render pass render commands.
constant bool gEncodeToMain         [[function_constant(AAPLFunctionConstIndexEncodeToMain)]];

// Toggled to visualize the results of culling.
constant bool gVisualizeCulling     [[function_constant(AAPLFunctionConstIndexVisualizeCulling)]];

constant bool gUseRasterizationRate [[function_constant(AAPLFunctionConstIndexRasterizationRate)]];

// Flag to indicate that commands should be tightly packed.
// If visualizing culling, all objects need to be rendered.
// If transparent, chunk order needs to be stable
constant bool gPackCommands         [[function_constant(AAPLFunctionConstIndexPackCommands)]];

constant bool gUseFilteredCulling   [[function_constant(AAPLFunctionConstIndexFilteredCulling)]];

// Structure containing all of the arguments for encoding commands.
struct AAPLEncodeArguments
{
    command_buffer cmdBuffer                            [[ id(AAPLEncodeArgsIndexCommandBuffer) ]];
    command_buffer cmdBufferDepthOnly                   [[ id(AAPLEncodeArgsIndexCommandBufferDepthOnly) ]];
    const device uint *indexBuffer                      [[ id(AAPLEncodeArgsIndexIndexBuffer) ]];
    device packed_float3 *vertexBuffer                  [[ id(AAPLEncodeArgsIndexVertexBuffer) ]];
    device packed_float3 *vertexNormalBuffer            [[ id(AAPLEncodeArgsIndexVertexNormalBuffer) ]];
    device packed_float3 *vertexTangentBuffer           [[ id(AAPLEncodeArgsIndexVertexTangentBuffer) ]];
    device float2 *uvBuffer                             [[ id(AAPLEncodeArgsIndexUVBuffer) ]];
    constant AAPLFrameConstants *frameDataBuffer        [[ id(AAPLEncodeArgsIndexFrameDataBuffer) ]];
    constant AAPLGlobalTextures *globalTexturesBuffer   [[ id(AAPLEncodeArgsIndexGlobalTexturesBuffer) ]];
    constant AAPLShaderLightParams *lightParamsBuffer   [[ id(AAPLEncodeArgsIndexLightParamsBuffer) ]];
};

//------------------------------------------------------------------------------

// Checks if a sphere is in a frustum.
static bool sphereInFrustum(constant AAPLCameraParams & cameraParams, const AAPLSphere sphere)
{
    return (min(
                min(sphere.distanceToPlane(cameraParams.worldFrustumPlanes[0]),
                    min(sphere.distanceToPlane(cameraParams.worldFrustumPlanes[1]),
                        sphere.distanceToPlane(cameraParams.worldFrustumPlanes[2]))),
                min(sphere.distanceToPlane(cameraParams.worldFrustumPlanes[3]),
                    min(sphere.distanceToPlane(cameraParams.worldFrustumPlanes[4]),
                        sphere.distanceToPlane(cameraParams.worldFrustumPlanes[5]))))) >= 0.0f;
}

// Generates an outcode for a clip space vertex.
uint outcode(float4 f)
{
    return
        (( f.x > f.w) << 0) |
        (( f.y > f.w) << 1) |
        (( f.z > f.w) << 2) |
        ((-f.x > f.w) << 3) |
        ((-f.y > f.w) << 4) |
        ((-f.z > f.w) << 5);
}

// Checks if a chunk is offscreen or occluded based on frustum and depth
//  culling.
static bool chunkOccluded(constant AAPLFrameConstants & frameData,
                          constant AAPLCameraParams & cameraParams,
                          constant rasterization_rate_map_data * rrData,
                          texture2d<float> depthPyramid,
                          const device AAPLMeshChunk &chunk)
{
    const AAPLBoundingBox3 worldBoundingBox = chunk.boundingBox;

    AAPLBoundingBox3 projBounds = AAPLBoundingBox3::sEmpty();

    // Frustum culling
    uint flags = 0xFF;
    for (uint i = 0; i < 8; ++i)
    {
        float4 f = cameraParams.viewProjectionMatrix * float4(worldBoundingBox.GetCorner(i), 1.0f);

        flags &= outcode(f);

        // prevent issues with corners behind camera
        f.z = max(f.z, 0.0f);

        float3 fp = f.xyz / f.w;
        fp.xy = fp.xy * float2(0.5, -0.5) + 0.5;
        fp = saturate(fp);
#if SUPPORT_RASTERIZATION_RATE
        if (gUseRasterizationRate)
        {
            rasterization_rate_map_decoder decoder(*rrData);
            fp.xy = decoder.map_screen_to_physical_coordinates(fp.xy * frameData.screenSize) * frameData.invPhysicalSize;
        }
#endif

        projBounds.Encapsulate(fp);
    }

    if (flags)
        return true;

    /*
    // Contribution culling
    float area = (projBounds.max.x - projBounds.min.x) * (projBounds.max.y - projBounds.min.y);

    if(area < 0.00001f)
        return true;
    */

    // Depth buffer culling.
    const uint2 texSize = uint2(depthPyramid.get_width(), depthPyramid.get_height());

    const float2 projExtent = float2(texSize) * (projBounds.max.xy - projBounds.min.xy);
    const uint lod = ceil(log2(max(projExtent.x, projExtent.y)));

    constexpr sampler pyramidGatherSampler(filter::nearest, mip_filter::nearest, address::clamp_to_edge);
    const uint2 lodSizeInLod0Pixels = texSize & (0xFFFFFFFF << lod);
    const float2 lodScale = float2(texSize) / float2(lodSizeInLod0Pixels);
    const float2 sampleLocationMin = projBounds.min.xy * lodScale;
    const float2 sampleLocationMax = projBounds.max.xy * lodScale;

    const float d0 = depthPyramid.sample(pyramidGatherSampler, float2(sampleLocationMin.x, sampleLocationMin.y), level(lod)).x;
    const float d1 = depthPyramid.sample(pyramidGatherSampler, float2(sampleLocationMin.x, sampleLocationMax.y), level(lod)).x;
    const float d2 = depthPyramid.sample(pyramidGatherSampler, float2(sampleLocationMax.x, sampleLocationMin.y), level(lod)).x;
    const float d3 = depthPyramid.sample(pyramidGatherSampler, float2(sampleLocationMax.x, sampleLocationMax.y), level(lod)).x;

    const float compareValue = projBounds.min.z;

    float maxDepth = max(max(d0, d1), max(d2, d3));
    return compareValue >= maxDepth;
}

//------------------------------------------------------------------------------

// Encodes the commands to render a chunk to a render_command.
__attribute__((always_inline))
static void encodeChunkCommand(thread render_command & cmd,
                               constant AAPLCameraParams & cameraParams,
                               constant AAPLEncodeArguments & encodeArgs,
                               const device AAPLShaderMaterial *materialBuffer,
                               uint materialIndex,
                               uint indexBegin,
                               uint indexCount)
{
    cmd.set_vertex_buffer(encodeArgs.frameDataBuffer, AAPLBufferIndexFrameData);
    cmd.set_vertex_buffer(&cameraParams, AAPLBufferIndexCameraParams);
    cmd.set_fragment_buffer(encodeArgs.frameDataBuffer, AAPLBufferIndexFrameData);
    cmd.set_fragment_buffer(&cameraParams, AAPLBufferIndexCameraParams);

    cmd.set_vertex_buffer(encodeArgs.vertexBuffer, AAPLBufferIndexVertexMeshPositions);
    cmd.set_vertex_buffer(encodeArgs.vertexNormalBuffer, AAPLBufferIndexVertexMeshNormals);
    cmd.set_vertex_buffer(encodeArgs.vertexTangentBuffer, AAPLBufferIndexVertexMeshTangents);
    cmd.set_vertex_buffer(encodeArgs.uvBuffer, AAPLBufferIndexVertexMeshGenerics);

    cmd.set_fragment_buffer(encodeArgs.globalTexturesBuffer, AAPLBufferIndexFragmentGlobalTextures);
    cmd.set_fragment_buffer(&materialBuffer[materialIndex], AAPLBufferIndexFragmentMaterial);
    cmd.set_fragment_buffer(encodeArgs.lightParamsBuffer, AAPLBufferIndexFragmentLightParams);

    cmd.draw_indexed_primitives(metal::primitive_type::triangle, indexCount, &encodeArgs.indexBuffer[indexBegin], 1);
}

// Encodes the commands to render a chunk to a render_command, only setting
//  buffers needed for a depth only pass which is quicker than the
//  encodeChunkCommand() function.
__attribute__((always_inline))
static void encodeChunkCommand_DepthOnly(thread render_command & cmd,
                                         constant AAPLCameraParams & cameraParams,
                                         constant AAPLEncodeArguments & encodeArgs,
                                         const device AAPLShaderMaterial *materialBuffer,
                                         uint materialIndex,
                                         uint indexBegin,
                                         uint indexCount)

{
#if SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
    if(gUseFilteredCulling)
    {
        // Pass `frameDataBuffer` to allow rendering from all cameras and not just `cameraParams`.
        cmd.set_vertex_buffer(encodeArgs.frameDataBuffer, AAPLBufferIndexFrameData);
    }
#endif
    cmd.set_vertex_buffer(&cameraParams, AAPLBufferIndexCameraParams);
    cmd.set_vertex_buffer(encodeArgs.vertexBuffer, AAPLBufferIndexVertexMeshPositions);

    if(gUseAlphaMask)
    {
        cmd.set_vertex_buffer(encodeArgs.uvBuffer, AAPLBufferIndexVertexMeshGenerics);
        cmd.set_fragment_buffer(&materialBuffer[materialIndex], AAPLBufferIndexFragmentMaterial);
    }

    cmd.draw_indexed_primitives(metal::primitive_type::triangle, indexCount, &encodeArgs.indexBuffer[indexBegin], 1);
}

//------------------------------------------------------------------------------

// Resets the length of a chunk execution range before it can be used as output
//  for encoding non-culled render commands.
kernel void resetChunkExecutionRange(device MTLIndirectCommandBufferExecutionRange & range [[ buffer(AAPLBufferIndexComputeExecutionRange) ]],
                                     constant uint & lengthResetValue [[ buffer(AAPLBufferIndexComputeExecutionRange + 1) ]])
{
    range.location = 0;
    range.length = lengthResetValue;
}

//----------------------------------------------------------

// Encodes a render command to render a chunk without culling.
kernel void encodeChunks(const uint tid                                   [[ thread_position_in_grid ]],
                         constant AAPLCullParams & cullParams             [[ buffer(AAPLBufferIndexCullParams) ]],
                         constant AAPLCameraParams & cameraParams         [[ buffer(AAPLBufferIndexCameraParams) ]],
                         constant AAPLEncodeArguments & encodeArgs        [[ buffer(AAPLBufferIndexComputeEncodeArguments) ]],
                         const device AAPLShaderMaterial * materialBuffer [[ buffer(AAPLBufferIndexComputeMaterial) ]],
                         const device AAPLMeshChunk * chunks              [[ buffer(AAPLBufferIndexComputeChunks) ]])
{
    if (tid >= cullParams.numChunks)
        return;

    const device AAPLMeshChunk &chunk = chunks[tid];

    if(gEncodeToDepthOnly)
    {
        render_command cmd(encodeArgs.cmdBufferDepthOnly, tid);
        encodeChunkCommand_DepthOnly(cmd, cameraParams, encodeArgs, materialBuffer, chunk.materialIndex, chunk.indexBegin, chunk.indexCount);
    }

    if(gEncodeToMain)
    {
        render_command cmd(encodeArgs.cmdBuffer, tid);
        encodeChunkCommand(cmd, cameraParams, encodeArgs, materialBuffer, chunk.materialIndex, chunk.indexBegin, chunk.indexCount);
    }
}

//------------------------------------------------------------------------------

// Encodes a render command to render a chunk with frustum and depth based
//  culling, dependent on function constants.
// Note: Needs to be dispatched with 128 wide threadgroup
kernel void encodeChunksWithCulling(const uint tid                                        [[ thread_position_in_grid ]],
                                    const uint indexInTG                                  [[ thread_index_in_threadgroup ]],
                                    constant AAPLCullParams & cullParams                  [[ buffer(AAPLBufferIndexCullParams) ]],
                                    constant AAPLCameraParams & cullCameraParams          [[ buffer(AAPLBufferIndexComputeCullCameraParams) ]],
                                    constant AAPLCameraParams & cameraParams              [[ buffer(AAPLBufferIndexCameraParams) ]],
                                    constant AAPLEncodeArguments & encodeArgs             [[ buffer(AAPLBufferIndexComputeEncodeArguments) ]],
                                    const device AAPLShaderMaterial * materialBuffer      [[ buffer(AAPLBufferIndexComputeMaterial) ]],
                                    device MTLIndirectCommandBufferExecutionRange & range [[ buffer(AAPLBufferIndexComputeExecutionRange) ]],
                                    const device AAPLMeshChunk * chunks                   [[ buffer(AAPLBufferIndexComputeChunks) ]],
                                    device AAPLChunkVizData * chunkViz                    [[ buffer(AAPLBufferIndexComputeChunkViz), function_constant(gVisualizeCulling) ]],
                                    constant AAPLFrameConstants & frameData               [[ buffer(AAPLBufferIndexComputeFrameData) ]],
                                    constant rasterization_rate_map_data * rrData         [[ buffer(AAPLBufferIndexRasterizationRateMap), function_constant(gUseRasterizationRate) ]],
                                    texture2d<float> depthPyramid                         [[ texture(0), function_constant(gUseOcclusionCulling) ]])
{
    bool validChunk = (tid < cullParams.numChunks);

    if (!gPackCommands && validChunk)
    {
        // reset commands since they're not packed
        render_command cmd(encodeArgs.cmdBuffer, tid);
        cmd.reset();
    }

    threadgroup uint visible[CULLING_THREADGROUP_SIZE];

    // Array of index count to add to the render command from the previous chunk
    threadgroup uint indexCountFollowingPrevious[CULLING_THREADGROUP_SIZE];

    indexCountFollowingPrevious[indexInTG] = 0;
    visible[indexInTG] = 0;

    const device AAPLMeshChunk &chunk = chunks[tid];

    bool occlusionCulled = false;
    bool frustumCulled = false;
    bool culled = false;

    if(validChunk)
    {
        if (!gPackCommands)
        {
            // reset commands since they're not packed
            render_command cmd(encodeArgs.cmdBuffer, tid);
            cmd.reset();
        }
        if(!gVisualizeCulling)
        {
            frustumCulled = !sphereInFrustum(cullCameraParams, chunk.boundingSphere);
        }

        if(!frustumCulled &&                // Chunk not already culled
           gUseOcclusionCulling &&  // Occlusion culling is enabled
           !gVisualizeCulling)      // Not visualizibng culling results
        {
            // Check if chunch is occlusiont cullde
            occlusionCulled = chunkOccluded(frameData,
                                            cullCameraParams,
                                            gUseRasterizationRate ? rrData : nullptr,
                                            depthPyramid, chunk);
        }

        culled = (frustumCulled || occlusionCulled);

        if(!culled)
        {
            visible[indexInTG] = 1;
        }
    }

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if(validChunk)
    {
        if(indexInTG > 0 && !culled)
        {
            const device AAPLMeshChunk &prev = chunks[tid-1];

            bool isContiguousWithPrevious;
            // Previous is also visible and can write this
            isContiguousWithPrevious = visible[indexInTG-1];

            // Share the same material
            isContiguousWithPrevious &= (chunk.materialIndex == prev.materialIndex);

            // Contiguous sets of indices
            isContiguousWithPrevious &= (chunk.indexBegin == (prev.indexBegin + prev.indexCount));

            indexCountFollowingPrevious[indexInTG] = isContiguousWithPrevious ? chunk.indexCount : 0;
        }
    }

    threadgroup_barrier(mem_flags::mem_threadgroup);

    // If a previous thread in the group would have already included this chunk in a draw call it issued
    bool writtenByAPreviousThreadInGroup = indexCountFollowingPrevious[indexInTG];

    if(!validChunk || (!gVisualizeCulling &&
                       (culled || writtenByAPreviousThreadInGroup)))
    {
        return;
    }

    uint indexCount = chunk.indexCount;
    if(!gVisualizeCulling)
    {
        // Check indexCountFollowingPrevious to see  if the index buffer for this chunk is
        // contiguous with the following chunks in this threadgroups.  If they are contiguous and
        // visible then we only need one indexed draw command that draws indices from start of this
        // chunk's indices to the end of last contiguous chunks index.  Here we also sum up the
        // number of indices to draw in our indirect draw call into the indexCount variable.
        for(uint localTGID = indexInTG+1, localTID = tid+1;
            (localTGID < CULLING_THREADGROUP_SIZE) &&  (localTID < cullParams.numChunks);
            localTGID++, localTID++)
        {
            uint extraIndexCount = indexCountFollowingPrevious[localTGID];
            indexCount += extraIndexCount;
            if(!extraIndexCount)
                break;
        }
    }

    device atomic_uint *chunkCount = (device atomic_uint *)&range.length;
    const uint cid = range.location + (gPackCommands ? atomic_fetch_add_explicit(chunkCount, 1, metal::memory_order_relaxed) : tid);

    if(gEncodeToDepthOnly)
    {
        render_command cmd(encodeArgs.cmdBufferDepthOnly, cid);
        encodeChunkCommand_DepthOnly(cmd, cameraParams, encodeArgs, materialBuffer, chunk.materialIndex, chunk.indexBegin, indexCount);
    }

    if(gEncodeToMain)
    {
        render_command cmd(encodeArgs.cmdBuffer, cid);

        // Acturally encode the draw command into the indirect command buffer
        encodeChunkCommand(cmd, cameraParams, encodeArgs, materialBuffer, chunk.materialIndex, chunk.indexBegin, indexCount);

        if (gVisualizeCulling)
        {
            uint cascadeCount = 0;
            for(uint i = 0 ; i < SHADOW_CASCADE_COUNT ; i++)
                cascadeCount += sphereInFrustum(encodeArgs.frameDataBuffer->shadowCameraParams[i], chunk.boundingSphere);
            chunkViz[cid].cascadeCount = cascadeCount;

            chunkViz[cid].index = cid + cullParams.offset;
            chunkViz[cid].cullType = frustumCulled ? AAPLCullResultFrustumCulled : (occlusionCulled ? AAPLCullResultOcclusionCulled : AAPLCullResultNotCulled);
            cmd.set_fragment_buffer(&chunkViz[cid], AAPLBufferIndexFragmentChunkViz);
        }
    }
}

#if SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
kernel void encodeChunksWithCullingFiltered(const uint tid                                          [[ thread_position_in_grid ]],
                                            const uint indexInTG                                    [[ thread_index_in_threadgroup ]],
                                            constant AAPLCullParams & cullParams                    [[ buffer(AAPLBufferIndexCullParams) ]],
                                            constant AAPLCameraParams & cullCameraParams1           [[ buffer(AAPLBufferIndexComputeCullCameraParams) ]],
                                            constant AAPLCameraParams & cullCameraParams2           [[ buffer(AAPLBufferIndexComputeCullCameraParams2) ]],
                                            constant AAPLCameraParams & cameraParams                [[ buffer(AAPLBufferIndexCameraParams) ]],
                                            constant AAPLEncodeArguments & encodeArgs               [[ buffer(AAPLBufferIndexComputeEncodeArguments) ]],
                                            const device AAPLShaderMaterial * materialBuffer        [[ buffer(AAPLBufferIndexComputeMaterial) ]],
                                            device MTLIndirectCommandBufferExecutionRange & range   [[ buffer(AAPLBufferIndexComputeExecutionRange) ]],
                                            device AAPLMeshChunk * chunks                           [[ buffer(AAPLBufferIndexComputeChunks) ]],
                                            device AAPLChunkVizData * chunkViz                      [[ buffer(AAPLBufferIndexComputeChunkViz), function_constant(gVisualizeCulling) ]],
                                            constant AAPLFrameConstants & frameData                 [[ buffer(AAPLBufferIndexComputeFrameData) ]],
                                            texture2d<float> depthPyramid1                          [[ texture(0), function_constant(gUseOcclusionCulling) ]],
                                            texture2d<float> depthPyramid2                          [[ texture(1), function_constant(gUseOcclusionCulling) ]])
{
    threadgroup uint visible[CULLING_THREADGROUP_SIZE];

    // Array of index count to add to the render command from the previous chunk
    threadgroup uint indexCountFollowingPrevious[CULLING_THREADGROUP_SIZE];

    bool validChunk = tid < cullParams.numChunks;

    bool wouldHaveBeenVisible = true;

    const uint chunkIdx = min(tid, cullParams.numChunks - 1);

    device AAPLMeshChunk &chunk = chunks[chunkIdx];

    bool frustumCulled = false;
    bool occlusionCulled = false;

    if(validChunk)
    {
        indexCountFollowingPrevious[indexInTG] = 0;
        visible[indexInTG] = 0;

        {
            frustumCulled = !sphereInFrustum(cullCameraParams1, chunk.boundingSphere);

            if (!gVisualizeCulling && frustumCulled)
                wouldHaveBeenVisible = false;

            occlusionCulled = ((gVisualizeCulling && frustumCulled) ||
                               (gUseOcclusionCulling &&
                                chunkOccluded(frameData, cullCameraParams1,
                                              nullptr,
                                              depthPyramid1, chunk)));

            if (!gVisualizeCulling && occlusionCulled)
                wouldHaveBeenVisible = false;
        }

        if(!wouldHaveBeenVisible)
        {
            frustumCulled = !sphereInFrustum(cullCameraParams2, chunk.boundingSphere);

            frustumCulled = (!gVisualizeCulling && frustumCulled);

            occlusionCulled = ((gVisualizeCulling && frustumCulled) ||
                               (gUseOcclusionCulling &&
                                chunkOccluded(frameData, cullCameraParams2,
                                              nullptr,
                                              depthPyramid2, chunk)));

            occlusionCulled = (!gVisualizeCulling && occlusionCulled);
        }

        visible[indexInTG] = 1;
    }

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if(validChunk && indexInTG > 0 && !wouldHaveBeenVisible && !(occlusionCulled || frustumCulled))
    {
        const device AAPLMeshChunk &prev = chunks[tid-1];

        bool isContiguousWithPrevious;
        // Previous is also visible and can write this
        isContiguousWithPrevious = visible[indexInTG-1];

        // Share the same material
        isContiguousWithPrevious &= (chunk.materialIndex == prev.materialIndex);

        // Contiguous sets of indices
        isContiguousWithPrevious &= (chunk.indexBegin == (prev.indexBegin + prev.indexCount));

        indexCountFollowingPrevious[indexInTG] = isContiguousWithPrevious ? chunk.indexCount : 0;
    }

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if(!validChunk ||                              // Less than the number of valid objects
       (!gVisualizeCulling &&                      // Culling visualization required
        (indexCountFollowingPrevious[indexInTG] || // Previous chunk will write this chunk
         wouldHaveBeenVisible ||                   // Visible to other camera
         occlusionCulled ||                        // Occlusion culled
         frustumCulled)))                          // Frustunm culled
    {
        return;
    }

    uint indexCount = chunk.indexCount;
    if(!gVisualizeCulling)
    {
        for(uint localTGID = indexInTG+1, localTID = tid+1;
            (localTGID < CULLING_THREADGROUP_SIZE) &&  (localTID < cullParams.numChunks);
            localTGID++, localTID++)
        {
            uint extraIndexCount = indexCountFollowingPrevious[localTGID];
            indexCount += extraIndexCount;
            if(!extraIndexCount)
                break;
        }
    }

    device atomic_uint *chunkCount = (device atomic_uint *)&range.length;
    const uint cid = range.location + (gPackCommands ? atomic_fetch_add_explicit(chunkCount, 1, metal::memory_order_relaxed) : tid);

    if(gEncodeToDepthOnly)
    {
        render_command cmd(encodeArgs.cmdBufferDepthOnly, cid);
        encodeChunkCommand_DepthOnly(cmd, cameraParams, encodeArgs, materialBuffer, chunk.materialIndex, chunk.indexBegin, indexCount);
    }

    if(gEncodeToMain)
    {
        render_command cmd(encodeArgs.cmdBuffer, cid);

        encodeChunkCommand(cmd, cameraParams, encodeArgs, materialBuffer, chunk.materialIndex, chunk.indexBegin, indexCount);

        if (gVisualizeCulling)
        {
            chunkViz[cid].index = cid + cullParams.offset;
            chunkViz[cid].cullType = frustumCulled ? AAPLCullResultFrustumCulled : (occlusionCulled ? AAPLCullResultOcclusionCulled : AAPLCullResultNotCulled);
            cmd.set_fragment_buffer(&chunkViz[cid], AAPLBufferIndexFragmentChunkViz);
        }
    }
}
#endif

