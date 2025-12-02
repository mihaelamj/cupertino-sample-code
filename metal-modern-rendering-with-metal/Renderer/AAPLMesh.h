/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for class storing data for to draw a mesh including vertex buffers, submeshes,
 materials, and vertex chunks.
*/

#import <Foundation/Foundation.h>

@class AAPLTextureManager;
@class AAPLMeshData;

struct AAPLMeshChunk;
struct AAPLSubMesh;
struct AAPLMaterial;

@protocol MTLTexture;
@protocol MTLBuffer;
@protocol MTLDevice;
@protocol MTLHeap;

// Stores runtime mesh information extracted from the source assets.
@interface AAPLMesh : NSObject <NSCopying>

// Geometry buffers for GPU access.
@property (nonatomic, readonly) id<MTLBuffer> vertices;
@property (nonatomic, readonly) id<MTLBuffer> normals;
@property (nonatomic, readonly) id<MTLBuffer> tangents;
@property (nonatomic, readonly) id<MTLBuffer> uvs;
@property (nonatomic, readonly) id<MTLBuffer> indices;
@property (nonatomic, readonly) id<MTLBuffer> chunks;

// Typed access for mesh data.
@property (nonatomic, readonly) const AAPLMeshChunk *chunkData;
@property (nonatomic, readonly) const AAPLSubMesh *meshes;
@property (nonatomic, readonly) const AAPLMaterial* materials;

// Counts of mesh subobjects.
@property (nonatomic, readonly) NSUInteger vertexCount;
@property (nonatomic, readonly) NSUInteger indexCount;

@property (nonatomic, readonly) NSUInteger chunkCount;
@property (nonatomic, readonly) NSUInteger meshCount;

@property (nonatomic, readonly) NSUInteger opaqueChunkCount;
@property (nonatomic, readonly) NSUInteger opaqueMeshCount;

@property (nonatomic, readonly) NSUInteger alphaMaskedChunkCount;
@property (nonatomic, readonly) NSUInteger alphaMaskedMeshCount;

@property (nonatomic, readonly) NSUInteger transparentChunkCount;
@property (nonatomic, readonly) NSUInteger transparentMeshCount;

@property (nonatomic, readonly) NSUInteger materialCount;

// Initialization from an AAPLMeshData asset.
- (instancetype)initWithMesh:(AAPLMeshData *)mesh device:(id<MTLDevice>)device textureManager:(AAPLTextureManager*)textureManager;

@end
