/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for mesh and submesh objects to use for managing models.
*/

@import Foundation;
@import MetalKit;
@import simd;

#include "AAPLShaderTypes.h"

// The app-specific submesh class that contains data to draw a submesh.
@interface AAPLSubmesh : NSObject

// A MetalKit submesh that contains the primitive type, index buffer, and index count
// for drawing all or part of its parent AAPLMesh object.
@property (nonatomic, readonly, nonnull) MTKSubmesh *metalKitSubmesh;

// Material textures (indexed by AAPLTextureIndex) to set in the Metal render command encoder
// before drawing the submesh. The renderer uses these for higher LODs.
@property (nonatomic, readonly, nonnull) NSArray<id<MTLTexture>> *textures;

@end

// The app-specific mesh class that contains vertex data describing the mesh and
// submesh object that describes how to draw parts of the mesh.
@interface AAPLMesh : NSObject

// Constructs an array of meshes from the provided file URL, which indicates the location of a model
//  file in a format Model I/O supports, such as OBJ, ABC, or USD.  The Model I/O vertex
//  descriptor defines the layout Model I/O uses to arrange the vertex data, while the
//  bufferAllocator supplies allocations of Metal buffers to store vertex and index data.
+ (nullable NSArray<AAPLMesh *> *) newMeshesFromURL:(nonnull NSURL *)url
                            modelIOVertexDescriptor:(nonnull MDLVertexDescriptor *)vertexDescriptor
                                        metalDevice:(nonnull id<MTLDevice>)device
                                              error:(NSError * __nullable * __nullable)error;

+ (nullable AAPLMesh *)newSkyboxMeshOnDevice:(nonnull id< MTLDevice >)device vertexDescriptor:(nonnull MDLVertexDescriptor *)vertexDescriptor;

+ (nullable AAPLMesh *)newSphereWithRadius:(float)radius onDevice:(nonnull id< MTLDevice >)device vertexDescriptor:(nonnull MDLVertexDescriptor *)vertexDescriptor;

+ (nullable AAPLMesh *)newPlaneWithDimensions:(vector_float2)dimensions onDevice:(nonnull id< MTLDevice >)device vertexDescriptor:(nonnull MDLVertexDescriptor *)vertexDescriptor;

// A MetalKit mesh that contains vertex buffers describing the shape of the mesh.
@property (nonatomic, readonly, nonnull) MTKMesh *metalKitMesh;

// An array of `AAPLSubmesh` objects that contains buffers and data for making a draw call
// and material data to set in a Metal render command encoder for that draw call.
@property (nonatomic, nonnull) NSArray<AAPLSubmesh*> *submeshes;

@end

__nullable id<MTLTexture> texture_from_radiance_file(NSString * __nonnull fileName, __nonnull id<MTLDevice> device, NSError * __nullable * __nullable error);
