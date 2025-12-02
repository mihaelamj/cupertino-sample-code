/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implemenation of class storing data to draw a mesh including vertex buffers, submeshes,
 materials, and vertex chunks.
*/

#import "AAPLMesh.h"

#import "AAPLTextureManager.h"
#import "AAPLMaterial.h"
#import "AAPLAsset.h"
#import "AAPLMeshTypes.h"
#import "AAPLCommon.h"

@implementation AAPLMesh
{
    // AAPLSubMesh data for CPU access.
    NSData *    _meshData;
    // AAPLMaterial data for CPU access.
    NSData *    _materialData;
    // AAPLMeshChunk data for CPU access.
    NSData *    _chunkData;
}

- (const AAPLMeshChunk *)chunkData
{
    return (const AAPLMeshChunk *)_chunkData.bytes;
}

- (const AAPLSubMesh *)meshes
{
    return (const AAPLSubMesh *)_meshData.bytes;
}

- (const AAPLMaterial *)materials
{
    return (const AAPLMaterial *)_materialData.bytes;
}

// Internal method to accumulate the required size of a heap for storing an
//  array of textures. Adds to the current accumulated size.
- (void) getTextureHeapSize:(NSArray<AAPLTextureData*>*)textures
                     device:(id<MTLDevice>)device
    accumulatedSizeAndAlign:(MTLSizeAndAlign &)accumulatedSizeAndAlign
             maxTextureSize:(NSUInteger)maxTextureSize
{
    for (AAPLTextureData *textureAsset in textures)
    {
        NSUInteger skippedMips = calculateMinMip(textureAsset, maxTextureSize);

        MTLTextureDescriptor *texDesc = [[MTLTextureDescriptor alloc] init];
        texDesc.width                   = MAX(textureAsset.width >> skippedMips, 1);
        texDesc.height                  = MAX(textureAsset.height >> skippedMips, 1);
        texDesc.mipmapLevelCount        = MAX(textureAsset.mipmapLevelCount - skippedMips, 1);
        texDesc.pixelFormat             = textureAsset.pixelFormat;
        texDesc.textureType             = MTLTextureType2D;
        texDesc.storageMode             = MTLStorageModePrivate;

        // Determine the size needed for the heap from the given descriptor
        MTLSizeAndAlign sizeAndAlign = [device heapTextureSizeAndAlignWithDescriptor:texDesc];

        accumulatedSizeAndAlign.align = MAX(accumulatedSizeAndAlign.align, sizeAndAlign.align);

        // Align the size so that more resources will fit after this texture
        accumulatedSizeAndAlign.size = alignUp(accumulatedSizeAndAlign.size, sizeAndAlign.align);
        accumulatedSizeAndAlign.size += sizeAndAlign.size;
    }
}

- (instancetype)initWithMesh:(AAPLMeshData *)mesh device:(id<MTLDevice>)device textureManager:(AAPLTextureManager*)textureManager
{
    self = [super init];

    if (self)
    {
        NSData *compressedVertexData    = mesh.vertexData;
        NSData *compressedNormalData    = mesh.normalData;
        NSData *compressedTangentData   = mesh.tangentData;
        NSData *compressedUVData        = mesh.uvData;
        NSData *compressedIndexData     = mesh.indexData;
        NSData *compressedMaterialData  = mesh.materialData;
        NSData *compressedMeshData      = mesh.meshData;
        NSData *compressedChunkData     = mesh.chunkData;

        MTLResourceOptions options = 0;
        uncompressData(compressedVertexData,    ^(size_t size) {
            self->_vertices = [device newBufferWithLength:size options:options];
            self->_vertices.label   = @"Vertices";
            return (uint8_t *)self->_vertices.contents;
        });
        uncompressData(compressedNormalData,    ^(size_t size) {
            self->_normals = [device newBufferWithLength:size options:options];
            self->_normals.label    = @"Normals";
            return (uint8_t *)self->_normals.contents;
        });
        uncompressData(compressedTangentData,   ^(size_t size) {
            self->_tangents = [device newBufferWithLength:size options:options];
            self->_tangents.label   = @"Tangents";
            return (uint8_t *)self->_tangents.contents;
        });
        uncompressData(compressedUVData,        ^(size_t size) {
            self->_uvs = [device newBufferWithLength:size options:options];
            self->_uvs.label        = @"UVs";
            return (uint8_t *)self->_uvs.contents;
        });
        uncompressData(compressedIndexData,     ^(size_t size) {
            self->_indices = [device newBufferWithLength:size options:options];
            self->_indices.label    = @"Indices";
            return (uint8_t *)self->_indices.contents;
        });
        uncompressData(compressedChunkData,     ^(size_t size) {
            self->_chunks = [device newBufferWithLength:size options:options];
            self->_chunks.label     = @"Chunks";
            return (uint8_t *)self->_chunks.contents;
        });

        if(!device.hasUnifiedMemory)
        {
            id<MTLCommandQueue> cmdQueue            = [device newCommandQueue];
            id<MTLCommandBuffer> cmdBuffer          = [cmdQueue commandBuffer];
            id<MTLBlitCommandEncoder> blitEncoder   = [cmdBuffer blitCommandEncoder];

            auto MoveToPrivate = [&](id<MTLBuffer> buffer)
            {
                id<MTLBuffer> newBuffer = [device newBufferWithLength:buffer.length options:MTLResourceStorageModePrivate];
                [blitEncoder copyFromBuffer:buffer sourceOffset:0 toBuffer:newBuffer destinationOffset:0 size:buffer.length];
                newBuffer.label = buffer.label;
                return newBuffer;
            };
            self->_vertices = MoveToPrivate(self->_vertices);
            self->_normals  = MoveToPrivate(self->_normals);
            self->_tangents = MoveToPrivate(self->_tangents);
            self->_uvs      = MoveToPrivate(self->_uvs);
            self->_indices  = MoveToPrivate(self->_indices);
            self->_chunks   = MoveToPrivate(self->_chunks);

            [blitEncoder endEncoding];
            [cmdBuffer commit];
        }

        _materialData   = uncompressData(compressedMaterialData);
        _meshData       = uncompressData(compressedMeshData);
        _chunkData      = uncompressData(compressedChunkData);

        _vertexCount            = mesh.vertexCount;
        _indexCount             = mesh.indexCount;

        _chunkCount             = mesh.chunkCount;
        _meshCount              = mesh.meshCount;

        _opaqueChunkCount       = mesh.opaqueChunkCount;
        _opaqueMeshCount        = mesh.opaqueMeshCount;

        _alphaMaskedChunkCount  = mesh.alphaMaskedChunkCount;
        _alphaMaskedMeshCount   = mesh.alphaMaskedMeshCount;

        _transparentChunkCount  = mesh.transparentChunkCount;
        _transparentMeshCount   = mesh.transparentMeshCount;

        _materialCount          = mesh.materialCount;

        NSArray<AAPLTextureData*>* textures = mesh.textures;

        NSUInteger maxTextureSize   = 4096;

#if !USE_TEXTURE_STREAMING
        NSUInteger requiredMem  = 0;
        const NSUInteger maxMem = textureManager.heap.size;

        for (AAPLTextureData *textureAsset in textures)
            maxTextureSize = MAX(maxTextureSize, MAX(textureAsset.width, textureAsset.height));

        NSUInteger origMaxTextureSize = maxTextureSize;

        do
        {
            MTLSizeAndAlign heapSizeAlign{ textureManager.heap.usedSize, 0 };
            [self getTextureHeapSize:textures device:device accumulatedSizeAndAlign:heapSizeAlign maxTextureSize:maxTextureSize];

            requiredMem = heapSizeAlign.size;

            if (requiredMem > maxMem)
            {
                maxTextureSize /= 2;
            }

        } while(requiredMem > maxMem);

        if(origMaxTextureSize > maxTextureSize)
            NSLog(@"Max texture size: %d.", (int)maxTextureSize);
#endif

        [textureManager addTextures:textures data:mesh.textureData maxTextureSize:maxTextureSize];

        NSLog(@"%@", textureManager.info);
    }

    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    AAPLMesh *copy = [[AAPLMesh alloc] init];

    copy->_vertices     = _vertices;
    copy->_normals      = _normals;
    copy->_tangents     = _tangents;
    copy->_uvs          = _uvs;
    copy->_indices      = _indices;
    copy->_materialData = _materialData;

    copy->_vertexCount      = _vertexCount;
    copy->_indexCount       = _indexCount;
    copy->_materialCount    = _materialCount;

    return copy;
}

@end
