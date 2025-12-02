/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the geometry objects classes.
*/

#import "Geometry.h"

using namespace simd;

float3 getTriangleNormal(float3 v0, float3 v1, float3 v2) {
    float3 e1 = normalize(v1 - v0);
    float3 e2 = normalize(v2 - v0);
    return cross(e1, e2);
}

@implementation GeometryObject
- (instancetype)initWithDevice:(id <MTLDevice>)device
{
    self = [super init];
    
    if (self) {
        _device = device;
#if !TARGET_OS_IPHONE
        if ([_device hasUnifiedMemory])
            _options = MTLResourceStorageModeShared;
        else
            _options = MTLResourceStorageModeManaged;
#else
        _options = MTLResourceStorageModeShared;
#endif
    }
    
    return self;
}
@end

@implementation PlaneGeometry

- (MTLPrimitiveAccelerationStructureDescriptor *)addPlane:(const std::vector<::simd_float3>&)planeVertices
{
    id <MTLBuffer> _vertexPositionBuffer;
    
    std::vector<uint16_t> _indices;
    std::vector<vector_float3> _vertices;
    std::vector<vector_float3> _normals;
    
    const float3 v0 = planeVertices[0];
    const float3 v1 = planeVertices[1];
    const float3 v2 = planeVertices[2];
    const float3 v3 = planeVertices[3];
    float3 n0 = getTriangleNormal(v0, v1, v2);
    float3 n1 = getTriangleNormal(v0, v2, v3);
    
    // Fill out the index buffer.
    const size_t baseIndex = 0;
    _indices.push_back(baseIndex + 0);
    _indices.push_back(baseIndex + 1);
    _indices.push_back(baseIndex + 2);
    _indices.push_back(baseIndex + 0);
    _indices.push_back(baseIndex + 2);
    _indices.push_back(baseIndex + 3);
    
    // Fill out the vertex position buffer.
    _vertices.push_back(v0);
    _vertices.push_back(v1);
    _vertices.push_back(v2);
    _vertices.push_back(v3);
    
    // Fill out the vertex normal buffer.
    _normals.push_back(normalize(n0 + n1));
    _normals.push_back(n0);
    _normals.push_back(normalize(n0 + n1));
    _normals.push_back(n1);
    
    // Create the geometry descriptor.
    MTLAccelerationStructureTriangleGeometryDescriptor *geometryDescriptor = [MTLAccelerationStructureTriangleGeometryDescriptor descriptor];
    MTLResourceOptions options = self.options;
    id <MTLDevice> device = self.device;
    // Create MTLBuffers for indices, vertices, and so on.
    _vertexIndexBuffer = [device newBufferWithLength:_indices.size() * sizeof(uint16_t) options:options];
    _vertexPositionBuffer = [device newBufferWithLength:_vertices.size() * sizeof(vector_float3) options:options];
    _vertexNormalBuffer = [device newBufferWithLength:_normals.size() * sizeof(vector_float3) options:options];
    // Copy the memory to the GPU.
    memcpy(_vertexIndexBuffer.contents, _indices.data(), _vertexIndexBuffer.length);
    memcpy(_vertexPositionBuffer.contents, _vertices.data(), _vertexPositionBuffer.length);
    memcpy(_vertexNormalBuffer.contents, _normals.data(), _vertexNormalBuffer.length);
#if !TARGET_OS_IPHONE
    if (![device hasUnifiedMemory])
    {
        [_vertexIndexBuffer didModifyRange:NSMakeRange(0, _vertexIndexBuffer.length)];
        [_vertexPositionBuffer didModifyRange:NSMakeRange(0, _vertexPositionBuffer.length)];
        [_vertexNormalBuffer didModifyRange:NSMakeRange(0, _vertexNormalBuffer.length)];
    }
#endif
    // Fill the geometry descriptor fields with the created MTLBuffers.
    geometryDescriptor.indexBuffer = _vertexIndexBuffer;
    geometryDescriptor.indexType = MTLIndexTypeUInt16;
    
    geometryDescriptor.vertexBuffer = _vertexPositionBuffer;
    geometryDescriptor.vertexStride = sizeof(float3);
    geometryDescriptor.triangleCount = _indices.size() / 3;
    
    // Assign each piece of geometry a consecutive slot in the intersection function table.
    geometryDescriptor.intersectionFunctionTableOffset = GEOMETRY_INTERSECTION_FUNCTION_TYPE_TRIANGLE;
    
    // Create a primitive acceleration structure descriptor to contain the single piece
    // of acceleration structure geometry.
    MTLPrimitiveAccelerationStructureDescriptor *_accelDescriptor = [MTLPrimitiveAccelerationStructureDescriptor descriptor];
    
    _accelDescriptor.geometryDescriptors = @[ geometryDescriptor ];
    
    return _accelDescriptor;
}

@end

@implementation CurveGeometry

- (MTLPrimitiveAccelerationStructureDescriptor *) addCurveWithControlPoints:(const std::vector<::simd_float3>&) controlPoints
                                                               curveIndices:(const std::vector<uint16_t>&) curveIndices
                                                                      radii:(const std::vector<float>&) radii
{
    id <MTLDevice> device = self.device;
    MTLResourceOptions options = self.options;
    
    size_t indexCount = curveIndices.size();
    size_t controlPointCount = controlPoints.size();
    
    // Create an acceleration structure geometry descriptor.
    MTLAccelerationStructureCurveGeometryDescriptor *geomDesc = [MTLAccelerationStructureCurveGeometryDescriptor descriptor];
    
    // Allocate the Metal buffers.
    id<MTLBuffer> _radiusBuffer;
    _radiusBuffer = [device newBufferWithLength:controlPointCount * sizeof(float) options:options];
    _controlPointBuffer = [device newBufferWithLength:controlPointCount * sizeof(float3) options:options];
    _curveIndexBuffer = [device newBufferWithLength:indexCount * sizeof(uint16_t) options:options];
    
    // Fill out the buffer containing the curve radius for each control point.
    memcpy(_radiusBuffer.contents, radii.data(), _radiusBuffer.length);
    
    // To save memory, a single index in the index buffer represents each curve segment, which represents the index of the first of N control points in the control point buffer.
    // The curve segment at index i is considered to belong to the same curve as segment i+1 if indexBuffer[i + 1] = indexBuffer[i] + 1 for linear, B-Spline, and Catmull-Rom curves
    // and if indexBuffer[i + 1] = indexBuffer[i] + segmentControlPointCount - 1 for Bézier curves.
    memcpy(_curveIndexBuffer.contents, curveIndices.data(), _curveIndexBuffer.length);
    
    // Fill out the control point buffer with the given values.
    memcpy(_controlPointBuffer.contents, controlPoints.data(), _controlPointBuffer.length);
    
#if !TARGET_OS_IPHONE
    if (![device hasUnifiedMemory])
    {
        [_radiusBuffer didModifyRange:NSMakeRange(0, _radiusBuffer.length)];
        [_controlPointBuffer didModifyRange:NSMakeRange(0, _controlPointBuffer.length)];
        [_curveIndexBuffer didModifyRange:NSMakeRange(0, _curveIndexBuffer.length)];
    }
#endif
    // Fill out the geometry descriptor.
    
    // The buffer containing the curve radius for each control point.
    geomDesc.radiusBuffer = _radiusBuffer;
    
    // The buffer containing the curve control points.
    geomDesc.controlPointBuffer = _controlPointBuffer;
    
    // The number of control points in the control point buffer.
    geomDesc.controlPointCount = controlPointCount;
    
    // The stride, in bytes, between the control points in the control point.
    geomDesc.controlPointStride = sizeof(float3);
    
    // The format of the control points in the control point buffer.
    geomDesc.controlPointFormat = MTLAttributeFormatFloat3;
    
    // The control point buffer offset.
    geomDesc.controlPointBufferOffset = 0;
    
    // The number of curve segments.
    geomDesc.segmentCount = indexCount;
    
    // The curve basis function for interpolating the control points.
    geomDesc.curveBasis = MTLCurveBasisCatmullRom;
    
    // Round curves: Cylindrical curves modeled as a circle swept along the curve,
    // more expensive to intersect and best-suited to close-up viewing.
    // Flat curves: Cheaper to intersect and best-suited to distant curves or curves
    // with small sections, such as hair or fur.
    geomDesc.curveType = MTLCurveTypeRound;
    
    // Unless disabled, the system inserts end caps between curve segments that don't belong
    // to the same curve, as well as at the beginning of the first curve segment and the end of the last curve segment.
    geomDesc.curveEndCaps = MTLCurveEndCapsDisk;
    
    // The number of control points per curve segment. The value needs to be 2, 3, or 4 as required by the curve basis.
    // Linear basis: Each curve segment needs to have two control points.
    // B-Spline basis: Each curve segment needs to have three or four control points.
    // Catmull-Rom and Bézier basis: Each curve segment needs to have four control points.
    geomDesc.segmentControlPointCount = 4;
    
    // The index buffer containing references to the control points in the control point buffer.
    geomDesc.indexBuffer = _curveIndexBuffer;
    
    // Index type.
    geomDesc.indexType = MTLIndexTypeUInt16;
    
    // Assign each piece of geometry a consecutive slot in the intersection function table.
    geomDesc.intersectionFunctionTableOffset = GEOMETRY_INTERSECTION_FUNCTION_TYPE_CATMULL_CURVE;
    
    // Create a primitive acceleration structure descriptor to contain the single piece
    // of acceleration structure geometry.
    MTLPrimitiveAccelerationStructureDescriptor *_accelDescriptor = [MTLPrimitiveAccelerationStructureDescriptor descriptor];
    
    _accelDescriptor.geometryDescriptors = @[ geomDesc ];
    
    return _accelDescriptor;
}

@end
