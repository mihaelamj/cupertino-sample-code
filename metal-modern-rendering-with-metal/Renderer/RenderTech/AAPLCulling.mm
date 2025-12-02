/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of class which performs cullong of a scene's objects using the GPU.
*/

#import "AAPLCulling.h"

#import "AAPLRenderer.h"
#import "AAPLMesh.h"
#import "AAPLCamera.h"
#import "AAPLCommon.h"
#import "AAPLShaderTypes.h"
#import "AAPLMeshTypes.h"

#import "../Shaders/AAPLCullingShared.h"

#import <Foundation/Foundation.h>

@implementation AAPLCulling
{
    // Device from initialization.
    id<MTLDevice>                   _device;

    // Compute pipelines for updating MTLIndirectCommandBufferExecutionRange objects.
    id <MTLComputePipelineState>    _resetChunkExecutionRangeState;

    // Compute pipelines for culling indexed by AAPLRenderCullType.
    id <MTLComputePipelineState>    _encodeChunksState[AAPLRenderCullTypeCount];
    id <MTLComputePipelineState>    _encodeChunksState_AlphaMask[AAPLRenderCullTypeCount];
    id <MTLComputePipelineState>    _encodeChunksState_Transparent[AAPLRenderCullTypeCount];

    id <MTLComputePipelineState>    _encodeChunksState_DepthOnly[AAPLRenderCullTypeCount];
    id <MTLComputePipelineState>    _encodeChunksState_DepthOnly_AlphaMask[AAPLRenderCullTypeCount];

#if SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
    id <MTLComputePipelineState>    _encodeChunksState_DepthOnly_Filtered;
    id <MTLComputePipelineState>    _encodeChunksState_DepthOnly_AlphaMask_Filtered;
#endif

    id <MTLComputePipelineState>    _encodeChunksState_Both[AAPLRenderCullTypeCount];
    id <MTLComputePipelineState>    _encodeChunksState_Both_AlphaMask[AAPLRenderCullTypeCount];

    id <MTLComputePipelineState>    _visualizeCullingState;
    id <MTLComputePipelineState>    _visualizeCullingState_AlphaMask;
    id <MTLComputePipelineState>    _visualizeCullingState_Transparent;

    // Argument encoder for configuring AAPLEncodeArguments objects.
    id <MTLArgumentEncoder>         _icbEncodeArgsEncoder;
}

- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                               library:(nonnull id<MTLLibrary>)library
                  useRasterizationRate:(BOOL)useRasterizationRate
        genCSMUsingVertexAmplification:(BOOL)genCSMUsingVertexAmplification
{
    self = [super init];
    if(self)
    {
        _device = device;

        [self rebuildPipelinesWithLibrary:library
                     useRasterizationRate:useRasterizationRate
           genCSMUsingVertexAmplification:genCSMUsingVertexAmplification];
    }

    return self;
}

-(void)rebuildPipelinesWithLibrary:(nonnull id<MTLLibrary>)library
              useRasterizationRate:(BOOL)useRasterizationRate
    genCSMUsingVertexAmplification:(BOOL)genCSMUsingVertexAmplification

{    
    _resetChunkExecutionRangeState = newComputePipelineState(library, @"resetChunkExecutionRange", @"ChunkExecRangeReset", nil);

    static const bool TRUE_VALUE = true;
    static const bool FALSE_VALUE = false;

    MTLFunctionConstantValues* fc = [MTLFunctionConstantValues new];

#if SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
    [fc setConstantValue:&genCSMUsingVertexAmplification type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexFilteredCulling];
#endif

    // ----------------------------------
    // CULLING STATES
    // ----------------------------------

    id <MTLFunction> encodeChunksFunction = [library newFunctionWithName:@"encodeChunks"];
    _icbEncodeArgsEncoder = [encodeChunksFunction newArgumentEncoderWithBufferIndex:AAPLBufferIndexComputeEncodeArguments];

    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexPackCommands];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexVisualizeCulling];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeAlphaMask];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeToDepthOnly];
    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeToMain];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexUseOcclusionCulling];
    [fc setConstantValue:&useRasterizationRate type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexRasterizationRate];

    _encodeChunksState[AAPLRenderCullTypeNone]         = newComputePipelineState(library, @"encodeChunks",
                                                                                 @"EncodeAllChunks",
                                                                                 fc);

    _encodeChunksState[AAPLRenderCullTypeFrustum]      = newComputePipelineState(library, @"encodeChunksWithCulling",
                                                                                 @"CullAndEncodeChunksFrustum",
                                                                                 fc);

    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexUseOcclusionCulling];
    _encodeChunksState[AAPLRenderCullTypeFrustumDepth] = newComputePipelineState(library, @"encodeChunksWithCulling",
                                                                                 @"CullAndEncodeChunksOccAndFrustum",
                                                                                 fc);

    // Depth Only

    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexPackCommands];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexVisualizeCulling];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeAlphaMask];
    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeToDepthOnly];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeToMain];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexUseOcclusionCulling];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexRasterizationRate];

    _encodeChunksState_DepthOnly[AAPLRenderCullTypeNone]         = newComputePipelineState(library, @"encodeChunks",
                                                                                           @"EncodeAllChunks_DepthOnly",
                                                                                           fc);

    _encodeChunksState_DepthOnly[AAPLRenderCullTypeFrustum]      = newComputePipelineState(library, @"encodeChunksWithCulling",
                                                                                           @"CullAndEncodeChunksFrustum_DepthOnly",
                                                                                           fc);

    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexUseOcclusionCulling];
    _encodeChunksState_DepthOnly[AAPLRenderCullTypeFrustumDepth] = newComputePipelineState(library, @"encodeChunksWithCulling",
                                                                                           @"CullAndEncodeChunksOccAndFrustum_DepthOnly",
                                                                                            fc);

#if SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
    if(genCSMUsingVertexAmplification)
    {
        _encodeChunksState_DepthOnly_Filtered = newComputePipelineState(library, @"encodeChunksWithCullingFiltered",
                                                                        @"CullAndEncodeChunksOccAndFrustum_Filtered",
                                                                        fc);
    }
#endif

    // Both

    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexPackCommands];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexVisualizeCulling];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeAlphaMask];
    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeToDepthOnly];
    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeToMain];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexUseOcclusionCulling];
    [fc setConstantValue:&useRasterizationRate type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexRasterizationRate];

    _encodeChunksState_Both[AAPLRenderCullTypeNone]         = newComputePipelineState(library, @"encodeChunks",
                                                                                      @"EncodeAllChunks_Both",
                                                                                      fc);

    _encodeChunksState_Both[AAPLRenderCullTypeFrustum]      = newComputePipelineState(library, @"encodeChunksWithCulling",
                                                                                      @"CullAndEncodeChunksFrustum_Both",
                                                                                      fc);

    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexUseOcclusionCulling];
    _encodeChunksState_Both[AAPLRenderCullTypeFrustumDepth] = newComputePipelineState(library, @"encodeChunksWithCulling",
                                                                                      @"CullAndEncodeChunksOccAndFrustum_Both",
                                                                                      fc);

    // Alpha Masked

    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexPackCommands];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexVisualizeCulling];
    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeAlphaMask];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeToDepthOnly];
    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeToMain];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexUseOcclusionCulling];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexRasterizationRate];

    _encodeChunksState_AlphaMask[AAPLRenderCullTypeNone]         = newComputePipelineState(library, @"encodeChunks",
                                                                                           @"EncodeAllChunks_AlphaMask",
                                                                                           fc);

    _encodeChunksState_AlphaMask[AAPLRenderCullTypeFrustum]      = newComputePipelineState(library, @"encodeChunksWithCulling",
                                                                                           @"CullAndEncodeChunksFrustum_AlphaMask",
                                                                                           fc);

    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexUseOcclusionCulling];
    _encodeChunksState_AlphaMask[AAPLRenderCullTypeFrustumDepth] = newComputePipelineState(library, @"encodeChunksWithCulling",
                                                                                           @"CullAndEncodeChunksOccAndFrustum_AlphaMask",
                                                                                           fc);

    // Alpha Masked Depth Only

    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexPackCommands];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexVisualizeCulling];
    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeAlphaMask];
    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeToDepthOnly];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeToMain];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexUseOcclusionCulling];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexRasterizationRate];

    _encodeChunksState_DepthOnly_AlphaMask[AAPLRenderCullTypeNone]         = newComputePipelineState(library, @"encodeChunks",
                                                                                                   @"EncodeAllChunks_DepthOnly_AlphaMask",
                                                                                                   fc);

    _encodeChunksState_DepthOnly_AlphaMask[AAPLRenderCullTypeFrustum]      = newComputePipelineState(library, @"encodeChunksWithCulling",
                                                                                                   @"CullAndEncodeChunksFrustum_DepthOnly_AlphaMask",
                                                                                                   fc);

    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexUseOcclusionCulling];
    _encodeChunksState_DepthOnly_AlphaMask[AAPLRenderCullTypeFrustumDepth] = newComputePipelineState(library, @"encodeChunksWithCulling",
                                                                                                   @"CullAndEncodeChunksOccAndFrustum_DepthOnly_AlphaMask",
                                                                                                   fc);

#if SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
    if(genCSMUsingVertexAmplification)
    {
        _encodeChunksState_DepthOnly_AlphaMask_Filtered = newComputePipelineState(library, @"encodeChunksWithCullingFiltered",
                                                                                  @"CullAndEncodeChunksOccAndFrustum_FilteredAlphaDepth",
                                                                                  fc);
    }
#endif

    // Alpha Masked Both

    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexPackCommands];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexVisualizeCulling];
    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeAlphaMask];
    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeToDepthOnly];
    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeToMain];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexUseOcclusionCulling];
    [fc setConstantValue:&useRasterizationRate type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexRasterizationRate];

    _encodeChunksState_Both_AlphaMask[AAPLRenderCullTypeNone]         = newComputePipelineState(library, @"encodeChunks",
                                                                                                @"EncodeAllChunks_Both_AlphaMask",
                                                                                                fc);

    _encodeChunksState_Both_AlphaMask[AAPLRenderCullTypeFrustum]      = newComputePipelineState(library, @"encodeChunksWithCulling",
                                                                                                @"CullAndEncodeChunksFrustum_Both_AlphaMask",
                                                                                                fc);

    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexUseOcclusionCulling];
    _encodeChunksState_Both_AlphaMask[AAPLRenderCullTypeFrustumDepth] = newComputePipelineState(library, @"encodeChunksWithCulling",
                                                                                                @"CullAndEncodeChunksOccAndFrustum_Both_AlphaMask",
                                                                                                fc);

    // Transparent

    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexPackCommands];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexVisualizeCulling];
    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeAlphaMask];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeToDepthOnly];
    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeToMain];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexUseOcclusionCulling];
    [fc setConstantValue:&useRasterizationRate type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexRasterizationRate];

    _encodeChunksState_Transparent[AAPLRenderCullTypeNone]         = newComputePipelineState(library, @"encodeChunks",
                                                                                           @"EncodeAllChunks_Transparent",
                                                                                           fc);

    _encodeChunksState_Transparent[AAPLRenderCullTypeFrustum]      = newComputePipelineState(library, @"encodeChunksWithCulling",
                                                                                           @"CullAndEncodeChunksFrustum_Transparent",
                                                                                           fc);

    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexUseOcclusionCulling];
    _encodeChunksState_Transparent[AAPLRenderCullTypeFrustumDepth] = newComputePipelineState(library, @"encodeChunksWithCulling",
                                                                                           @"CullAndEncodeChunksOccAndFrustum_Transparent",
                                                                                            fc);

    // Visualization

    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexPackCommands];
    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexVisualizeCulling];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeAlphaMask];
    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeToDepthOnly];
    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeToMain];
    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexUseOcclusionCulling];

    _visualizeCullingState = newComputePipelineState(library, @"encodeChunksWithCulling",
                                                     @"CullingStateVisualization",
                                                     fc);

    [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexEncodeAlphaMask];

    _visualizeCullingState_AlphaMask = newComputePipelineState(library, @"encodeChunksWithCulling",
                                                               @"CullingStateVisualization_AlphaMask",
                                                               fc);

    _visualizeCullingState_Transparent = _visualizeCullingState_AlphaMask;
}

- (void)initCommandData:(AAPLICBData &)commandData
                forMesh:(AAPLMesh *)mesh
               chunkViz:(BOOL)chunkViz
              frameData:(id<MTLBuffer>)frameData
   globalTexturesBuffer:(id<MTLBuffer>)globalTexturesBuffer
      lightParamsBuffer:(id<MTLBuffer>)lightParamsBuffer
{
    MTLIndirectCommandBufferDescriptor *icbDescriptor   = [MTLIndirectCommandBufferDescriptor new];
    icbDescriptor.commandTypes                          = MTLIndirectCommandTypeDrawIndexed;
    icbDescriptor.inheritPipelineState                  = YES;
    icbDescriptor.inheritBuffers                        = NO;
    icbDescriptor.maxVertexBufferBindCount              = AAPLBufferIndexVertexICBBufferCount;
    icbDescriptor.maxFragmentBufferBindCount            = AAPLBufferIndexFragmentICBBufferCount;

    commandData.commandBuffer                   = [_device newIndirectCommandBufferWithDescriptor:icbDescriptor maxCommandCount:mesh.opaqueChunkCount options:0];
    commandData.commandBuffer.label             = @"Opaque ICB";
    commandData.commandBuffer_alphaMask         = [_device newIndirectCommandBufferWithDescriptor:icbDescriptor maxCommandCount:mesh.alphaMaskedChunkCount options:0];
    commandData.commandBuffer_alphaMask.label   = @"AlphaMask ICB";
    commandData.commandBuffer_transparent       = [_device newIndirectCommandBufferWithDescriptor:icbDescriptor maxCommandCount:mesh.transparentChunkCount options:0];
    commandData.commandBuffer_transparent.label = @"Transparent ICB";

    icbDescriptor.maxVertexBufferBindCount      = AAPLBufferIndexVertexDepthOnlyICBBufferCount;
    icbDescriptor.maxFragmentBufferBindCount    = 0;
    commandData.commandBuffer_depthOnly         = [_device newIndirectCommandBufferWithDescriptor:icbDescriptor maxCommandCount:mesh.opaqueChunkCount options:0];
    commandData.commandBuffer_depthOnly.label   = @"Opaque DepthOnly ICB";

    icbDescriptor.maxVertexBufferBindCount              = AAPLBufferIndexVertexDepthOnlyICBAlphaMaskBufferCount;
    icbDescriptor.maxFragmentBufferBindCount            = AAPLBufferIndexFragmentDepthOnlyICBAlphaMaskBufferCount;
    commandData.commandBuffer_depthOnly_alphaMask       = [_device newIndirectCommandBufferWithDescriptor:icbDescriptor maxCommandCount:mesh.alphaMaskedChunkCount options:0];
    commandData.commandBuffer_depthOnly_alphaMask.label = @"AlphaMask DepthOnly ICB";

    if (chunkViz)
    {
        commandData.chunkVizBuffer          = [_device newBufferWithLength:sizeof(AAPLChunkVizData) * mesh.chunkCount options:MTLResourceStorageModePrivate];
        commandData.chunkVizBuffer.label    = @"ChunkViz";
    }

    const int numExecutionRanges = 3;

    commandData.executionRangeBuffer        = [_device newBufferWithLength:sizeof(MTLIndirectCommandBufferExecutionRange) * numExecutionRanges options:MTLResourceStorageModeShared]; // Read back in callback
    commandData.executionRangeBuffer.label  = @"Execution Range Buffer";

    commandData.icbEncodeArgsBuffer         = [_device newBufferWithLength:_icbEncodeArgsEncoder.encodedLength options:0];
    commandData.icbEncodeArgsBuffer.label   = @"ICB Encode Args Buffer";

    commandData.icbEncodeArgsBuffer_alphaMask         = [_device newBufferWithLength:_icbEncodeArgsEncoder.encodedLength options:0];
    commandData.icbEncodeArgsBuffer_alphaMask.label   = @"ICB Encode Args Buffer Alpha Mask";

    commandData.icbEncodeArgsBuffer_transparent       = [_device newBufferWithLength:_icbEncodeArgsEncoder.encodedLength options:0];
    commandData.icbEncodeArgsBuffer_transparent.label = @"ICB Encode Args Buffer Transparent";

    id <MTLBuffer> icbEncodeArgsBuffers[numExecutionRanges] = { commandData.icbEncodeArgsBuffer, commandData.icbEncodeArgsBuffer_alphaMask, commandData.icbEncodeArgsBuffer_transparent  };

    id <MTLIndirectCommandBuffer> commandBuffers[numExecutionRanges]          = { commandData.commandBuffer, commandData.commandBuffer_alphaMask, commandData.commandBuffer_transparent };
    id <MTLIndirectCommandBuffer> commandBuffersDepthOnly[numExecutionRanges] = { commandData.commandBuffer_depthOnly, commandData.commandBuffer_depthOnly_alphaMask, nil };

    for(uint i = 0; i < numExecutionRanges; ++i)
    {
        id <MTLIndirectCommandBuffer> depthOnly = commandBuffersDepthOnly[i] ? commandBuffersDepthOnly[i] : commandBuffers[i];
        [_icbEncodeArgsEncoder setArgumentBuffer:icbEncodeArgsBuffers[i] offset:0];
        [_icbEncodeArgsEncoder setIndirectCommandBuffer:commandBuffers[i] atIndex:AAPLEncodeArgsIndexCommandBuffer];
        [_icbEncodeArgsEncoder setIndirectCommandBuffer:depthOnly         atIndex:AAPLEncodeArgsIndexCommandBufferDepthOnly];
        [_icbEncodeArgsEncoder setBuffer:mesh.indices            offset:0 atIndex:AAPLEncodeArgsIndexIndexBuffer];
        [_icbEncodeArgsEncoder setBuffer:mesh.vertices           offset:0 atIndex:AAPLEncodeArgsIndexVertexBuffer];
        [_icbEncodeArgsEncoder setBuffer:mesh.normals            offset:0 atIndex:AAPLEncodeArgsIndexVertexNormalBuffer];
        [_icbEncodeArgsEncoder setBuffer:mesh.tangents           offset:0 atIndex:AAPLEncodeArgsIndexVertexTangentBuffer];
        [_icbEncodeArgsEncoder setBuffer:mesh.uvs                offset:0 atIndex:AAPLEncodeArgsIndexUVBuffer];
        [_icbEncodeArgsEncoder setBuffer:frameData               offset:0 atIndex:AAPLEncodeArgsIndexFrameDataBuffer];
        [_icbEncodeArgsEncoder setBuffer:globalTexturesBuffer    offset:0 atIndex:AAPLEncodeArgsIndexGlobalTexturesBuffer];
        [_icbEncodeArgsEncoder setBuffer:lightParamsBuffer       offset:0 atIndex:AAPLEncodeArgsIndexLightParamsBuffer];
    }
}

// Internal helper method to encode the commands required for culling chunks of
//  a mesh and generating an ICB.
- (void)encodeCulling:(nonnull id<MTLComputeCommandEncoder>)encoder
         cullPipeline:(nonnull id <MTLComputePipelineState>)cullPipeline
  icbEncodeArgsBuffer:(nonnull id <MTLBuffer>)icbEncodeArgsBuffer
           chunkCount:(uint32_t)chunkCount
          chunkOffset:(uint32_t)chunkOffset
         packCommands:(bool)packCommands
{
    AAPLCullParams cullParams;
    cullParams.numChunks  = chunkCount;
    cullParams.offset     = chunkOffset;

    [encoder setBuffer:icbEncodeArgsBuffer offset:0 atIndex:AAPLBufferIndexComputeEncodeArguments];

    // Reset.
    {
        const uint32_t lengthResetValue = packCommands ? 0 : cullParams.numChunks;

        [encoder setComputePipelineState:_resetChunkExecutionRangeState];
        [encoder setBytes:&lengthResetValue length:sizeof(lengthResetValue) atIndex:AAPLBufferIndexComputeExecutionRange + 1];

        [encoder dispatchThreadgroups:MTLSizeMake(1, 1, 1) threadsPerThreadgroup:MTLSizeMake(1, 1, 1)];
    }

    // Fill.
    {
        [encoder setComputePipelineState:cullPipeline];
        [encoder setBytes:&cullParams length:sizeof(AAPLCullParams) atIndex:AAPLBufferIndexCullParams];

        [encoder setBufferOffset:sizeof(AAPLMeshChunk) * cullParams.offset atIndex:AAPLBufferIndexComputeChunks];

        const MTLSize threadgroupSize = MTLSizeMake(CULLING_THREADGROUP_SIZE, 1, 1);
        const MTLSize threadgroupCount = MTLSizeMake(divideRoundUp(cullParams.numChunks, threadgroupSize.width), 1, 1);

        [encoder dispatchThreadgroups:threadgroupCount threadsPerThreadgroup:threadgroupSize];
    }
}

- (void)executeCulling:(AAPLICBData&)commandData
         frameViewData:(AAPLFrameViewData&)frameViewData
       frameDataBuffer:(nonnull id<MTLBuffer>)frameDataBuffer
              cullMode:(AAPLRenderCullType)cullMode
        pyramidTexture:(nonnull id<MTLTexture>)pyramidTexture
              mainPass:(BOOL)mainPass
             depthOnly:(BOOL)depthOnly
                  mesh:(nonnull AAPLMesh *)mesh
        materialBuffer:(nonnull id<MTLBuffer>)materialBuffer
                rrData:(nullable id<MTLBuffer>)rrMapData
             onEncoder:(nonnull id<MTLComputeCommandEncoder>)encoder
{
    [encoder pushDebugGroup:@"Encode chunks"];

    if(mainPass)
    {
        [encoder useResource:commandData.commandBuffer usage:MTLResourceUsageRead|MTLResourceUsageWrite];
        [encoder useResource:commandData.commandBuffer_alphaMask usage:MTLResourceUsageRead|MTLResourceUsageWrite];
        [encoder useResource:commandData.commandBuffer_transparent usage:MTLResourceUsageRead|MTLResourceUsageWrite];
    }

    if(depthOnly)
    {
        [encoder useResource:commandData.commandBuffer_depthOnly usage:MTLResourceUsageRead|MTLResourceUsageWrite];
        [encoder useResource:commandData.commandBuffer_depthOnly_alphaMask usage:MTLResourceUsageRead|MTLResourceUsageWrite];
    }

    id <MTLComputePipelineState> opaqueCullPipeline, alphaMaskCullPipeline, transparentCullPipeline;

    if(cullMode == AAPLRenderCullTypeVisualization)
    {
        opaqueCullPipeline          = _visualizeCullingState;
        alphaMaskCullPipeline       = _visualizeCullingState_AlphaMask;
        transparentCullPipeline     = _visualizeCullingState_Transparent;
    }
    else if(mainPass && depthOnly)
    {
        opaqueCullPipeline          = _encodeChunksState_Both[cullMode];
        alphaMaskCullPipeline       = _encodeChunksState_Both_AlphaMask[cullMode];
        transparentCullPipeline     = _encodeChunksState_Transparent[cullMode]; // Not Both since Transparent doesn't write depth-only
    }
    else if(depthOnly)
    {
        opaqueCullPipeline          = _encodeChunksState_DepthOnly[cullMode];
        alphaMaskCullPipeline       = _encodeChunksState_DepthOnly_AlphaMask[cullMode];
        transparentCullPipeline     = nil;
    }
    else
    {
        opaqueCullPipeline          = _encodeChunksState[cullMode];
        alphaMaskCullPipeline       = _encodeChunksState_AlphaMask[cullMode];
        transparentCullPipeline     = _encodeChunksState_Transparent[cullMode];
    }

    [encoder setBuffer:frameViewData.cullParamBuffer offset:0 atIndex:AAPLBufferIndexComputeCullCameraParams];
    [encoder setBuffer:frameViewData.cameraParamsBuffer offset:0 atIndex:AAPLBufferIndexCameraParams];
    [encoder setBuffer:materialBuffer offset:0 atIndex:AAPLBufferIndexComputeMaterial];

    [encoder setBuffer:commandData.chunkVizBuffer offset:0 atIndex:AAPLBufferIndexComputeChunkViz];
    [encoder setBuffer:mesh.chunks offset:0 atIndex:AAPLBufferIndexComputeChunks];

    [encoder setBuffer:commandData.executionRangeBuffer offset:0 atIndex:AAPLBufferIndexComputeExecutionRange];
    [encoder setBuffer:frameDataBuffer offset:0 atIndex:AAPLBufferIndexComputeFrameData];
#if SUPPORT_RASTERIZATION_RATE
    [encoder setBuffer:rrMapData offset:0 atIndex:AAPLBufferIndexRasterizationRateMap];
#endif

    [encoder setTexture:pyramidTexture atIndex:0];

    const bool packCommands = !(cullMode == AAPLRenderCullTypeNone || cullMode == AAPLRenderCullTypeVisualization);

    // Cull opaque draws
    {
        [self encodeCulling:encoder
               cullPipeline:opaqueCullPipeline
        icbEncodeArgsBuffer:commandData.icbEncodeArgsBuffer
                 chunkCount:(uint32_t)mesh.opaqueChunkCount
                chunkOffset:0U
               packCommands:packCommands];
    }

    // Cull alpha mask draws
    {
        [encoder setBufferOffset:sizeof(MTLIndirectCommandBufferExecutionRange)
                         atIndex:AAPLBufferIndexComputeExecutionRange];

        if(commandData.chunkVizBuffer)
            [encoder setBufferOffset:sizeof(AAPLChunkVizData) * mesh.opaqueChunkCount
                             atIndex:AAPLBufferIndexComputeChunkViz];

        [self encodeCulling:encoder
               cullPipeline:alphaMaskCullPipeline
        icbEncodeArgsBuffer:commandData.icbEncodeArgsBuffer_alphaMask
                 chunkCount:(uint32_t)mesh.alphaMaskedChunkCount
                chunkOffset:(uint32_t)mesh.opaqueChunkCount
               packCommands:packCommands];
    }

    // Cull transparent draws
    if(transparentCullPipeline)
    {
        [encoder setBufferOffset:sizeof(MTLIndirectCommandBufferExecutionRange) * 2
                         atIndex:AAPLBufferIndexComputeExecutionRange];

        if(commandData.chunkVizBuffer)
            [encoder setBufferOffset:sizeof(AAPLChunkVizData) * (mesh.opaqueChunkCount + mesh.alphaMaskedChunkCount)
                             atIndex:AAPLBufferIndexComputeChunkViz];

        [self encodeCulling:encoder
               cullPipeline:transparentCullPipeline
        icbEncodeArgsBuffer:commandData.icbEncodeArgsBuffer_transparent
                 chunkCount:(uint32_t)mesh.transparentChunkCount
                chunkOffset:(uint32_t)(mesh.opaqueChunkCount + mesh.alphaMaskedChunkCount)
               packCommands:mainPass ? false : packCommands]; // dont pack transparent chunks because we need stable ordering for blending
    }

    [encoder popDebugGroup];
}

#if SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
- (void)executeCullingFiltered:(AAPLICBData&)commandData
                frameViewData1:(AAPLFrameViewData&)frameViewData1
                frameViewData2:(AAPLFrameViewData&)frameViewData2
               frameDataBuffer:(nonnull id<MTLBuffer>)frameDataBuffer
                      cullMode:(AAPLRenderCullType)cullMode
               pyramidTexture1:(nonnull id<MTLTexture>)pyramidTexture1
               pyramidTexture2:(nonnull id<MTLTexture>)pyramidTexture2
                          mesh:(nonnull AAPLMesh *)mesh
                materialBuffer:(nonnull id<MTLBuffer>)materialBuffer
                     onEncoder:(nonnull id<MTLComputeCommandEncoder>)encoder;
{
    [encoder pushDebugGroup:@"Encode chunks filtered"];

    [encoder useResource:commandData.commandBuffer_depthOnly usage:MTLResourceUsageRead|MTLResourceUsageWrite];
    [encoder useResource:commandData.commandBuffer_depthOnly_alphaMask usage:MTLResourceUsageRead|MTLResourceUsageWrite];

    id <MTLComputePipelineState> opaqueCullPipeline          = _encodeChunksState_DepthOnly_Filtered;
    id <MTLComputePipelineState> alphaMaskCullPipeline       = _encodeChunksState_DepthOnly_AlphaMask_Filtered;

    [encoder setBuffer:frameViewData1.cullParamBuffer offset:0 atIndex:AAPLBufferIndexComputeCullCameraParams];
    [encoder setBuffer:frameViewData2.cullParamBuffer offset:0 atIndex:AAPLBufferIndexComputeCullCameraParams2];
    [encoder setBuffer:frameViewData2.cameraParamsBuffer offset:0 atIndex:AAPLBufferIndexCameraParams];
    [encoder setBuffer:materialBuffer offset:0 atIndex:AAPLBufferIndexComputeMaterial];

    [encoder setBuffer:commandData.chunkVizBuffer offset:0 atIndex:AAPLBufferIndexComputeChunkViz];
    [encoder setBuffer:mesh.chunks offset:0 atIndex:AAPLBufferIndexComputeChunks];

    [encoder setBuffer:commandData.executionRangeBuffer offset:0 atIndex:AAPLBufferIndexComputeExecutionRange];

    [encoder setTexture:pyramidTexture1 atIndex:0];
    [encoder setTexture:pyramidTexture2 atIndex:1];

    const bool packCommands = !(cullMode == AAPLRenderCullTypeNone || cullMode == AAPLRenderCullTypeVisualization);

    // Cull opaque draws
    {
        [self encodeCulling:encoder
               cullPipeline:opaqueCullPipeline
        icbEncodeArgsBuffer:commandData.icbEncodeArgsBuffer
                 chunkCount:(uint32_t)mesh.opaqueChunkCount
                chunkOffset:0U
               packCommands:packCommands];
    }

    // Cull alpha mask draws
    {
        [encoder setBufferOffset:sizeof(MTLIndirectCommandBufferExecutionRange)
                         atIndex:AAPLBufferIndexComputeExecutionRange];

        if(commandData.chunkVizBuffer)
            [encoder setBufferOffset:sizeof(AAPLChunkVizData) * mesh.opaqueChunkCount
                             atIndex:AAPLBufferIndexComputeChunkViz];

        [self encodeCulling:encoder
               cullPipeline:alphaMaskCullPipeline
        icbEncodeArgsBuffer:commandData.icbEncodeArgsBuffer_alphaMask
                 chunkCount:(uint32_t)mesh.alphaMaskedChunkCount
                chunkOffset:(uint32_t)mesh.opaqueChunkCount
               packCommands:packCommands];
    }

    // No transparent

    [encoder popDebugGroup];
}
#endif // SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION

- (void)resetIndirectCommandBuffersForViews:(nonnull AAPLICBData*)commandData
                                  viewCount:(NSUInteger)viewCount
                                   mainPass:(BOOL)mainPass
                                  depthOnly:(BOOL)depthOnly
                                       mesh:(nonnull AAPLMesh *)mesh
                            onCommandBuffer:(nonnull id <MTLCommandBuffer>)commandBuffer;
{
#if OPTIMIZE_COMMAND_BUFFERS
    id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
    blitEncoder.label = @"ICB Reset";
    for (NSUInteger viewIndex = 0; viewIndex < viewCount; ++viewIndex)
    {
        if(mainPass)
        {
            [blitEncoder resetCommandsInBuffer:commandData[viewIndex].commandBuffer withRange:NSMakeRange(0, mesh.opaqueChunkCount)];
            [blitEncoder resetCommandsInBuffer:commandData[viewIndex].commandBuffer_alphaMask withRange:NSMakeRange(0, mesh.alphaMaskedChunkCount)];
            [blitEncoder resetCommandsInBuffer:commandData[viewIndex].commandBuffer_transparent withRange:NSMakeRange(0, mesh.transparentChunkCount)];
        }

        if(depthOnly)
        {
            [blitEncoder resetCommandsInBuffer:commandData[viewIndex].commandBuffer_depthOnly withRange:NSMakeRange(0, mesh.opaqueChunkCount)];
            [blitEncoder resetCommandsInBuffer:commandData[viewIndex].commandBuffer_depthOnly_alphaMask withRange:NSMakeRange(0, mesh.alphaMaskedChunkCount)];
        }
    }
    [blitEncoder endEncoding];
#endif // OPTIMIZE_COMMAND_BUFFERS
}

- (void)optimizeIndirectCommandBuffersForViews:(nonnull AAPLICBData*)commandData
                                     viewCount:(NSUInteger)viewCount
                                      mainPass:(BOOL)mainPass
                                     depthOnly:(BOOL)depthOnly
                                          mesh:(nonnull AAPLMesh *)mesh
                               onCommandBuffer:(nonnull id <MTLCommandBuffer>)commandBuffer;
{
#if OPTIMIZE_COMMAND_BUFFERS
    id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
    blitEncoder.label = @"ICB Optimize";
    for (NSUInteger viewIndex = 0; viewIndex < viewCount; ++viewIndex)
    {
        if(mainPass)
        {
            [blitEncoder optimizeIndirectCommandBuffer:commandData[viewIndex].commandBuffer withRange:NSMakeRange(0, mesh.opaqueChunkCount)];
            [blitEncoder optimizeIndirectCommandBuffer:commandData[viewIndex].commandBuffer_alphaMask withRange:NSMakeRange(0, mesh.alphaMaskedChunkCount)];
            [blitEncoder optimizeIndirectCommandBuffer:commandData[viewIndex].commandBuffer_transparent withRange:NSMakeRange(0, mesh.transparentChunkCount)];
        }

        if(depthOnly)
        {
            [blitEncoder optimizeIndirectCommandBuffer:commandData[viewIndex].commandBuffer_depthOnly withRange:NSMakeRange(0, mesh.opaqueChunkCount)];
            [blitEncoder optimizeIndirectCommandBuffer:commandData[viewIndex].commandBuffer_depthOnly_alphaMask withRange:NSMakeRange(0, mesh.alphaMaskedChunkCount)];
        }
    }
    [blitEncoder endEncoding];
#endif // OPTIMIZE_COMMAND_BUFFERS
}

@end

