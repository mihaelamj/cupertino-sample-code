/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for types shared between Metal and ObjC mesh culling code.
*/

// Enum to index the members of the AAPLEncodeArguments argument buffer.
typedef enum AAPLEncodeArgsIndex
{
    AAPLEncodeArgsIndexCommandBuffer,
    AAPLEncodeArgsIndexCommandBufferDepthOnly,
    AAPLEncodeArgsIndexIndexBuffer,
    AAPLEncodeArgsIndexVertexBuffer,
    AAPLEncodeArgsIndexVertexNormalBuffer,
    AAPLEncodeArgsIndexVertexTangentBuffer,
    AAPLEncodeArgsIndexUVBuffer,
    AAPLEncodeArgsIndexFrameDataBuffer,
    AAPLEncodeArgsIndexGlobalTexturesBuffer,
    AAPLEncodeArgsIndexLightParamsBuffer,
} AAPLEncodeArgsIndex;

// Results of the culling operation.
typedef enum AAPLCullResult
{
    AAPLCullResultNotCulled                 = 0,
    AAPLCullResultFrustumCulled             = 1,
    AAPLCullResultOcclusionCulled           = 2,
} AAPLCullResult;

#define CULLING_THREADGROUP_SIZE  (128)

// Parameters for the culling process.
typedef struct AAPLCullParams
{
    uint numChunks;         // The number of chunks to process.
    uint offset;            // The offset for writing the chunks.  Allows thread relative indexing
                            // which shaders can reuse between opaque and alpha mask.
} AAPLCullParams;

// Chunk visualization data.
//  Populated by culling to be applied during rendering.
typedef struct AAPLChunkVizData
{
    uint index;         // Index for chunk - can be used for coloring.
    uint cullType;      // Type of culling for this chunk - AAPLCullResult.
    uint cascadeCount;  // Number of overlapping cascades.
} AAPLChunkVizData;

