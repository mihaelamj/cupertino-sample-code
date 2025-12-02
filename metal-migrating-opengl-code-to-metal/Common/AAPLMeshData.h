/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for mesh and submesh objects used for managing model data.
*/

#import <simd/simd.h>
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

struct AAPLVertexData
{
    vector_float3 position;
    vector_float3 normal;
    vector_float2 texcoord;
};

// App-specific submesh class containing data to draw a submesh.
@interface AAPLSubmeshData : NSObject

@property (nonatomic, readonly, nonnull) uint32_t *indexData;

@property (nonatomic, readonly) NSUInteger indexCount;

@property (nonatomic, readonly, nonnull) NSURL *baseColorMapURL;

@end

// App-specific mesh class containing vertex data describing the mesh, and the submesh object describing
//   how to draw parts of the mesh.
@interface AAPLMeshData : NSObject

- (nullable instancetype)initWithURL:(nonnull NSURL*)URL
                               error:(NSError * __nullable * __nullable)error;

@property (nonatomic, readonly, nonnull) struct AAPLVertexData *vertexData;

@property (nonatomic, readonly) NSUInteger vertexCount;

// An array of `AAPLSubmesh` objects containing buffers and data to make a draw call and material data
// to set in a render command encoder for that draw call.
@property (nonatomic, readonly, nonnull) NSDictionary<NSString *, AAPLSubmeshData*> *submeshes;

@end
