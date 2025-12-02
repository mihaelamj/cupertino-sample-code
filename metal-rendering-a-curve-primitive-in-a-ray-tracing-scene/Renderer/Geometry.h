/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the geometry objects classes.
*/

#ifndef Geometry_h
#define Geometry_h

#import <Metal/Metal.h>
#include <simd/simd.h>
#import <vector>

@interface GeometryObject : NSObject

// The Metal device for creating the acceleration structures.
@property (nonatomic, readonly) id <MTLDevice> device;

// The Metal resource options for creating the acceleration structures.
@property (nonatomic, readonly) MTLResourceOptions options;

// Initializer.
- (instancetype)initWithDevice:(id <MTLDevice>)device;

@end

@interface PlaneGeometry : GeometryObject

// The normal buffer.
@property (nonatomic, readwrite) id<MTLBuffer> vertexNormalBuffer;

// The index buffer.
@property (nonatomic, readwrite) id<MTLBuffer> vertexIndexBuffer;

// Create a plane geometry with given vertices.
- (MTLPrimitiveAccelerationStructureDescriptor *)addPlane:(const std::vector<::simd_float3>&)planeVertices;

@end

@interface CurveGeometry : GeometryObject

// The control point buffer.
@property (nonatomic, readwrite) id<MTLBuffer> controlPointBuffer;

// The index buffer.
@property (nonatomic, readwrite) id<MTLBuffer> curveIndexBuffer;

// Create a curve geometry with a given control point and index buffers.
- (MTLPrimitiveAccelerationStructureDescriptor *) addCurveWithControlPoints:(const std::vector<::simd_float3>&) controlPoints
                                                               curveIndices:(const std::vector<uint16_t>&) curveIndices
                                                                      radii:(const std::vector<float>&) radii;
@end

enum GEOMETRY_INTERSECTION_FUNCTION_TYPE
{
    GEOMETRY_INTERSECTION_FUNCTION_TYPE_TRIANGLE = 0,
    GEOMETRY_INTERSECTION_FUNCTION_TYPE_CATMULL_CURVE
};

#endif /* Geometry_h */
