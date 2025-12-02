/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the class that describes objects in a scene.
*/

#ifndef Scene_h
#define Scene_h

#import <Metal/Metal.h>

#import "Transforms.h"
#import "ShaderTypes.h"

#define FACE_MASK_NONE       0
#define FACE_MASK_NEGATIVE_X (1 << 0)
#define FACE_MASK_POSITIVE_X (1 << 1)
#define FACE_MASK_NEGATIVE_Y (1 << 2)
#define FACE_MASK_POSITIVE_Y (1 << 3)
#define FACE_MASK_NEGATIVE_Z (1 << 4)
#define FACE_MASK_POSITIVE_Z (1 << 5)
#define FACE_MASK_ALL        ((1 << 6) - 1)

struct BoundingBox
{
    MTLPackedFloat3 min;
    MTLPackedFloat3 max;
};

MTLResourceOptions getManagedBufferStorageMode();

// Represents the vertex data for a single keyframe of primitive motion.
@interface TriangleKeyframeData : NSObject

// The Metal device for allocating buffers.
@property (nonatomic, readonly) id <MTLDevice> device;

// The number of triangles.
@property (nonatomic, readonly) NSUInteger triangleCount;

// The vertex position data.
@property (nonatomic, readonly) MTLMotionKeyframeData *vertexData;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDevice:(id <MTLDevice>)device;

// Upload the primitives to the Metal buffers so the GPU can access them.
- (void)uploadToBuffers;

// The stride, between keyframes, of resources the sample encodes
//  into the keyframe argument buffer.
- (NSUInteger)resourcesStride;

// Encode the keyframe resources into the keyframe argument buffer.
- (void)encodeResourcesToBuffer:(id <MTLBuffer>)resourceBuffer
                         offset:(NSUInteger)offset;

// Mark resources that the keyframe argument buffer references indirectly.
- (void)markResourcesAsUsedWithEncoder:(id <MTLComputeCommandEncoder>)encoder;

// Add a cube to the key frame.
- (void)addCubeWithFaces:(unsigned int)faceMask
                   color:(vector_float3)color
               transform:(matrix_float4x4)transform
           inwardNormals:(bool)inwardNormals;

// Add the vertex data from a 3D model located at the given URL.
- (void)addGeometryWithURL:(NSURL *)URL;

@end

// Represents a piece of geometry in a scene. Each piece of geometry has triangle
// vertex data for one or more keyframes, and each geometry object has its own
// primitive acceleration structure. The sample creates copies, or "instances" of
// geometry objects using the `GeometryInstance` class.
@interface Geometry : NSObject

// The Metal device that creates the acceleration structures.
@property (nonatomic, readonly) id <MTLDevice> device;

- (instancetype)init NS_UNAVAILABLE;

// The initializer.
- (instancetype)initWithKeyframes:(NSArray <TriangleKeyframeData *> *)keyframes;

// Upload the keyframes to the Metal buffers so the GPU can access them.
- (void)uploadToBuffers;

// Get the primitive acceleration structure descriptor for this piece of
// geometry.
- (MTLPrimitiveAccelerationStructureDescriptor *)accelerationStructureDescriptor;

// The stride, between geometries, of resource data encoded into the resource
// argument buffer.
- (NSUInteger)resourcesStride;

// Encode the resources into the resource argument buffer.
- (void)encodeResourcesToBuffer:(id <MTLBuffer>)resourceBuffer
                         offset:(NSUInteger)offset;

// Mark resources that the resource argument buffer references indirectly buffer
// as "used".
- (void)markResourcesAsUsedWithEncoder:(id <MTLComputeCommandEncoder>)encoder;

@end

// Represents an instance, or copy, of a piece of geometry in a scene.
// Each instance has its own set of transformation matrices that determine
// where to place it in the scene in one or more keyframes.
@interface GeometryInstance : NSObject

// The geometry to use in the instance.
@property (nonatomic, readonly) Geometry *geometry;

// Transformation matrices that describe where to place the geometry in the
// scene for each keyframe.
@property (nonatomic, readonly) matrix_float4x4 *transforms;

// The number of keyframes of the transformation matrix data.
@property (nonatomic, readonly) NSUInteger instanceMotionKeyframeCount;

// The mask for filtering out the intersections between rays and different
// types of geometry.
@property (nonatomic, readonly) unsigned int mask;

- (instancetype)init NS_UNAVAILABLE;

// The initializer for multiple keyframes.
- (instancetype)initWithGeometry:(Geometry *)geometry
                      transforms:(matrix_float4x4 *)transforms
     instanceMotionKeyframeCount:(NSUInteger)instanceMotionKeyframeCount
                            mask:(unsigned int)mask;

// The initializer for a single keyframe.
- (instancetype)initWithGeometry:(Geometry *)geometry
                       transform:(matrix_float4x4)transform
                            mask:(unsigned int)mask;

@end

// Represents an entire scene, including different types of geometry,
// instances of that geometry, lights, and a camera.
@interface Scene : NSObject

// The device for creating the scene.
@property (nonatomic, readonly) id <MTLDevice> device;

// The array of geometries in the scene.
@property (nonatomic, readonly) NSArray <Geometry *> *geometries;

// The array of geometry instances in the scene.
@property (nonatomic, readonly) NSArray <GeometryInstance *> *instances;

// The buffer that contains the lights.
@property (nonatomic, readonly) id <MTLBuffer> lightBuffer;

// The number of lights in the light buffer.
@property (nonatomic, readonly) NSUInteger lightCount;

// The camera "position" vector.
@property (nonatomic) vector_float3 cameraPosition;

// The camera "target" vector. The camera faces this point.
@property (nonatomic) vector_float3 cameraTarget;

// The camera "up" vector.
@property (nonatomic) vector_float3 cameraUp;

// The initializer.
- (instancetype)initWithDevice:(id <MTLDevice>)device;

// Create the scene with motion blur.
+ (Scene *)newMotionBlurSceneWithDevice:(id <MTLDevice>)device
                     usePrimitiveMotion:(BOOL)usePrimitiveMotion;

// Add a piece of geometry to the scene.
- (void)addGeometry:(Geometry *)mesh;

// Add an instance of a piece of geometry to the scene.
- (void)addInstance:(GeometryInstance *)instance;

// Add a light to the scene.
- (void)addLight:(AreaLight)light;

// Upload all scene data to the Metal buffers so the GPU can access the data.
- (void)uploadToBuffers;

@end

#endif
