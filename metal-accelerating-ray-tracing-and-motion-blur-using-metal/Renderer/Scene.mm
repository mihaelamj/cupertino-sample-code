/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the class that describes objects in a scene.
*/

#import "Scene.h"

#import <vector>

#import <ModelIO/ModelIO.h>

using namespace simd;

MTLResourceOptions getManagedBufferStorageMode()
{
#if !TARGET_OS_IPHONE
    return MTLResourceStorageModeManaged;
#else
    return MTLResourceStorageModeShared;
#endif
}

float3 getTriangleNormal(float3 v0, float3 v1, float3 v2)
{
    float3 e1 = normalize(v1 - v0);
    float3 e2 = normalize(v2 - v0);

    return cross(e1, e2);
}

@implementation TriangleKeyframeData
{
    id <MTLBuffer> _vertexPositionBuffer;
    id <MTLBuffer> _vertexNormalBuffer;
    id <MTLBuffer> _vertexColorBuffer;

    std::vector<vector_float3> _vertices;
    std::vector<vector_float3> _normals;
    std::vector<vector_float3> _colors;
    
    id <MTLArgumentEncoder> _resourceEncoder;
}

- (instancetype)initWithDevice:(id <MTLDevice>)device
{
    self = [super init];
    
    if (self) {
        _device = device;
        
        [self createResourceEncoder];
    }
    
    return self;
}

// Create an argument encoder to encode references to the normal and color buffers
// for this keyframe.
- (void)createResourceEncoder
{
    NSMutableArray <MTLArgumentDescriptor *> *arguments = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < 2; i++) {
        MTLArgumentDescriptor *argDesc = [[MTLArgumentDescriptor alloc] init];
        
        argDesc.dataType = MTLDataTypePointer;
        argDesc.index = i;
        
        [arguments addObject:argDesc];
    }
    
    _resourceEncoder = [_device newArgumentEncoderWithArguments:arguments];
}

- (NSUInteger)triangleCount
{
    return _vertices.size() / 3;
}

- (void)uploadToBuffers
{
    MTLResourceOptions options = getManagedBufferStorageMode();

    _vertexPositionBuffer = [_device newBufferWithLength:_vertices.size() * sizeof(vector_float3) options:options];
    _vertexNormalBuffer = [_device newBufferWithLength:_normals.size() * sizeof(vector_float3) options:options];
    _vertexColorBuffer = [_device newBufferWithLength:_colors.size() * sizeof(vector_float3) options:options];

    memcpy(_vertexPositionBuffer.contents, &_vertices[0], _vertexPositionBuffer.length);
    memcpy(_vertexNormalBuffer.contents, &_normals[0], _vertexNormalBuffer.length);
    memcpy(_vertexColorBuffer.contents, &_colors[0], _vertexColorBuffer.length);

#if !TARGET_OS_IPHONE
    [_vertexPositionBuffer didModifyRange:NSMakeRange(0, _vertexPositionBuffer.length)];
    [_vertexNormalBuffer didModifyRange:NSMakeRange(0, _vertexNormalBuffer.length)];
    [_vertexColorBuffer didModifyRange:NSMakeRange(0, _vertexColorBuffer.length)];
#endif
}

- (MTLMotionKeyframeData *)vertexData
{
    MTLMotionKeyframeData *vertexData = [[MTLMotionKeyframeData alloc] init];
    
    vertexData.buffer = _vertexPositionBuffer;
    
    return vertexData;
}

- (NSUInteger)resourcesStride
{
    return _resourceEncoder.encodedLength;
}

- (void)encodeResourcesToBuffer:(id <MTLBuffer>)resourceBuffer
                         offset:(NSUInteger)offset
{
    [_resourceEncoder setArgumentBuffer:resourceBuffer offset:offset];
    
    [_resourceEncoder setBuffer:_vertexNormalBuffer offset:0 atIndex:0];
    [_resourceEncoder setBuffer:_vertexColorBuffer  offset:0 atIndex:1];
}

- (void)markResourcesAsUsedWithEncoder:(id <MTLComputeCommandEncoder>)encoder
{
    [encoder useResource:_vertexNormalBuffer usage:MTLResourceUsageRead];
    [encoder useResource:_vertexColorBuffer usage:MTLResourceUsageRead];
}

- (void)addCubeFaceWithCubeVertices:(float3 *)cubeVertices
                              color:(float3)color
                                 i0:(unsigned int)i0
                                 i1:(unsigned int)i1
                                 i2:(unsigned int)i2
                                 i3:(unsigned int)i3
                      inwardNormals:(bool)inwardNormals
{
    float3 v0 = cubeVertices[i0];
    float3 v1 = cubeVertices[i1];
    float3 v2 = cubeVertices[i2];
    float3 v3 = cubeVertices[i3];

    float3 n0 = getTriangleNormal(v0, v1, v2);
    float3 n1 = getTriangleNormal(v0, v2, v3);

    if (inwardNormals) {
        n0 = -n0;
        n1 = -n1;
    }

    _vertices.push_back(v0);
    _vertices.push_back(v1);
    _vertices.push_back(v2);
    _vertices.push_back(v0);
    _vertices.push_back(v2);
    _vertices.push_back(v3);

    for (int i = 0; i < 3; i++)
        _normals.push_back(n0);

    for (int i = 0; i < 3; i++)
        _normals.push_back(n1);

    for (int i = 0; i < 6; i++)
        _colors.push_back(color);
}

- (void)addCubeWithFaces:(unsigned int)faceMask
                   color:(vector_float3)color
               transform:(matrix_float4x4)transform
           inwardNormals:(bool)inwardNormals
{
    float3 cubeVertices[] = {
        vector3(-0.5f, -0.5f, -0.5f),
        vector3( 0.5f, -0.5f, -0.5f),
        vector3(-0.5f,  0.5f, -0.5f),
        vector3( 0.5f,  0.5f, -0.5f),
        vector3(-0.5f, -0.5f,  0.5f),
        vector3( 0.5f, -0.5f,  0.5f),
        vector3(-0.5f,  0.5f,  0.5f),
        vector3( 0.5f,  0.5f,  0.5f),
    };

    for (int i = 0; i < 8; i++) {
        float3 vertex = cubeVertices[i];

        float4 transformedVertex = vector4(vertex.x, vertex.y, vertex.z, 1.0f);
        transformedVertex = transform * transformedVertex;

        cubeVertices[i] = transformedVertex.xyz;
    }

    unsigned int cubeIndices[][4] = {
        { 0, 4, 6, 2 },
        { 1, 3, 7, 5 },
        { 0, 1, 5, 4 },
        { 2, 6, 7, 3 },
        { 0, 2, 3, 1 },
        { 4, 5, 7, 6 }
    };

    for (unsigned face = 0; face < 6; face++) {
        if (faceMask & (1 << face)) {
            [self addCubeFaceWithCubeVertices:cubeVertices
                                        color:color
                                           i0:cubeIndices[face][0]
                                           i1:cubeIndices[face][1]
                                           i2:cubeIndices[face][2]
                                           i3:cubeIndices[face][3]
                                inwardNormals:inwardNormals];
        }
    }
}

- (void)addGeometryWithURL:(NSURL *)URL
{
    MDLAsset *asset = [[MDLAsset alloc] initWithURL:URL];
    
    NSAssert(asset, @"Could not open %@", URL);
    
    MDLMesh *mesh = (MDLMesh *)asset[0];
    
    struct MeshVertex {
        float position[3];
        float normal[3];
        float uv[2];
    };
    
    MeshVertex *meshVertices = (MeshVertex *)mesh.vertexBuffers[0].map.bytes;
    
    for (MDLSubmesh *submesh in mesh.submeshes) {
        uint32_t *indices = (uint32_t *)submesh.indexBuffer.map.bytes;
        
        vector_float3 color = [submesh.material propertyWithSemantic:MDLMaterialSemanticBaseColor].float3Value;
        
        for (NSUInteger i = 0; i < submesh.indexCount; i++) {
            uint32_t index = indices[i];
            
            MeshVertex & vertex = meshVertices[index];
            
            _vertices.push_back(vector3(vertex.position[0], vertex.position[1], vertex.position[2]));
            _normals.push_back(vector3(vertex.normal[0], vertex.normal[1], vertex.normal[2]));
            _colors.push_back(color);
        }
    }
}

@end

@implementation Geometry
{
    NSArray <TriangleKeyframeData *> *_keyframes;
    
    id <MTLBuffer> _keyframeBuffer;
    
    id <MTLArgumentEncoder> _resourceEncoder;
}

- (instancetype)initWithKeyframes:(NSArray<TriangleKeyframeData *> *)keyframes
{
    self = [super init];

    if (self) {
        _device = keyframes[0].device;
        
        _keyframes = keyframes;
        
        [self createResourceEncoder];
    }

    return self;
}

// Create an argument encoder to encode a pointer to the keyframe buffer
// and the number of keyframes.  The keyframe buffer, in turn, encodes pointers
// to the color and normal buffers for each keyframe.
- (void)createResourceEncoder
{
    NSMutableArray <MTLArgumentDescriptor *> *arguments = [NSMutableArray array];
    
    MTLArgumentDescriptor *descriptor = [[MTLArgumentDescriptor alloc] init];
        
    descriptor.index = 0;
    descriptor.dataType = MTLDataTypePointer;
        
    [arguments addObject:descriptor];

    descriptor = [[MTLArgumentDescriptor alloc] init];
        
    descriptor.index = 1;
    descriptor.dataType = MTLDataTypeUInt;
        
    [arguments addObject:descriptor];
    
    _resourceEncoder = [_device newArgumentEncoderWithArguments:arguments];
}

- (void)uploadToBuffers
{
    for (TriangleKeyframeData *keyframe in _keyframes)
        [keyframe uploadToBuffers];
    
    MTLResourceOptions options = getManagedBufferStorageMode();
    
    NSUInteger keyframeStride = _keyframes[0].resourcesStride;
    
    _keyframeBuffer = [_device newBufferWithLength:keyframeStride * _keyframes.count options:options];
    
    // Encode each keyframe's resources into the keyframe buffer.
    for (NSUInteger i = 0; i < _keyframes.count; i++) {
        [_keyframes[i] encodeResourcesToBuffer:_keyframeBuffer
                                        offset:i * keyframeStride];
    }
    
#if !TARGET_OS_IPHONE
    [_keyframeBuffer didModifyRange:NSMakeRange(0, _keyframeBuffer.length)];
#endif
}

- (MTLPrimitiveAccelerationStructureDescriptor *)accelerationStructureDescriptor
{
    // Metal represents each piece of geometry in an acceleration structure using a
    // geometry descriptor.  The sample uses a triangle geometry descriptor to represent
    // triangle geometry.  Each triangle geometry descriptor can have its own
    // vertex buffer, index buffer, and triangle count.  The sample uses a single geometry
    // descriptor because it packs all of the vertex data into a single buffer.

    MTLAccelerationStructureGeometryDescriptor *geometryDescriptor = nil;
    if(_keyframes.count > 1){
        MTLAccelerationStructureMotionTriangleGeometryDescriptor *triangleGeometryDescriptor =
            [MTLAccelerationStructureMotionTriangleGeometryDescriptor descriptor];

        NSMutableArray *vertexBuffers = [NSMutableArray array];

        for (TriangleKeyframeData *keyframe in _keyframes)
            [vertexBuffers addObject:keyframe.vertexData];

        triangleGeometryDescriptor.vertexBuffers = vertexBuffers;
        triangleGeometryDescriptor.vertexStride = sizeof(float3);
        triangleGeometryDescriptor.triangleCount = _keyframes[0].triangleCount;

        geometryDescriptor = triangleGeometryDescriptor;
    }else{
        MTLAccelerationStructureTriangleGeometryDescriptor *triangleGeometryDescriptor =
            [MTLAccelerationStructureTriangleGeometryDescriptor descriptor];

        triangleGeometryDescriptor.vertexBuffer = _keyframes[0].vertexData.buffer;
        triangleGeometryDescriptor.vertexStride = sizeof(float3);
        triangleGeometryDescriptor.triangleCount = _keyframes[0].triangleCount;

        geometryDescriptor = triangleGeometryDescriptor;
    }

    // Create a primitive acceleration structure descriptor to contain the single piece
    // of acceleration structure geometry.
    MTLPrimitiveAccelerationStructureDescriptor *descriptor = [MTLPrimitiveAccelerationStructureDescriptor descriptor];

    descriptor.geometryDescriptors = @[ geometryDescriptor ];
    
    // Configure the primitive motion blur parameters.
    descriptor.motionKeyframeCount = _keyframes.count;
    descriptor.motionStartTime = 0.0f;
    descriptor.motionEndTime = 1.0f;
    descriptor.motionStartBorderMode = MTLMotionBorderModeClamp;
    descriptor.motionEndBorderMode = MTLMotionBorderModeClamp;

    return descriptor;
}

- (NSUInteger)resourcesStride
{
    return _resourceEncoder.encodedLength;
}

- (void)encodeResourcesToBuffer:(id <MTLBuffer>)resourceBuffer
                         offset:(NSUInteger)offset
{
    [_resourceEncoder setArgumentBuffer:resourceBuffer offset:offset];
    
    // Encode the pointer to the keyframe buffer.
    [_resourceEncoder setBuffer:_keyframeBuffer offset:0 atIndex:0];
    
    // Encode the number of keyframes.
    uint32_t *primitiveMotionKeyframeCount = (uint32_t *)[_resourceEncoder constantDataAtIndex:1];
    
    *primitiveMotionKeyframeCount = (uint32_t)_keyframes.count;
}

- (void)markResourcesAsUsedWithEncoder:(id <MTLComputeCommandEncoder>)encoder {
    [encoder useResource:_keyframeBuffer usage:MTLResourceUsageRead];
    
    for (TriangleKeyframeData *keyframe in _keyframes)
        [keyframe markResourcesAsUsedWithEncoder:encoder];
}

@end

@implementation GeometryInstance

- (instancetype)initWithGeometry:(Geometry *)geometry
                      transforms:(matrix_float4x4 *)transforms
     instanceMotionKeyframeCount:(NSUInteger)instanceMotionKeyframeCount
                            mask:(unsigned int)mask
{
    self = [super init];

    if (self) {
        _geometry = geometry;
        _instanceMotionKeyframeCount = instanceMotionKeyframeCount;
        _mask = mask;
        
        _transforms = (matrix_float4x4 *)malloc(sizeof(matrix_float4x4) * instanceMotionKeyframeCount);
        memcpy(_transforms, transforms, sizeof(matrix_float4x4) * instanceMotionKeyframeCount);
    }

    return self;
}

- (instancetype)initWithGeometry:(Geometry *)geometry
                       transform:(matrix_float4x4)transform
                            mask:(unsigned int)mask
{
    return [self initWithGeometry:geometry
                       transforms:&transform
      instanceMotionKeyframeCount:1
                             mask:mask];
}

- (void)dealloc {
    if (_transforms) {
        free(_transforms);
        _transforms = nil;
    }
}

@end

@implementation Scene {
    NSMutableArray <Geometry *> *_geometries;
    NSMutableArray <GeometryInstance *> *_instances;

    std::vector<AreaLight> _lights;
}

- (NSArray <Geometry *> *)geometries {
    return _geometries;
}

- (NSUInteger)lightCount {
    return (NSUInteger)_lights.size();
}

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    self = [super init];

    if (self) {
        _device = device;

        _geometries = [[NSMutableArray alloc] init];
        _instances = [[NSMutableArray alloc] init];

        _cameraPosition = vector3(0.0f, 0.0f, -1.0f);
        _cameraTarget = vector3(0.0f, 0.0f, 0.0f);
        _cameraUp = vector3(0.0f, 1.0f, 0.0f);
    }

    return self;
}

- (void)addGeometry:(Geometry *)mesh {
    [_geometries addObject:mesh];
}

- (void)addInstance:(GeometryInstance *)instance {
    [_instances addObject:instance];
}

- (void)addLight:(AreaLight)light {
    _lights.push_back(light);
}

- (void)uploadToBuffers {
    for (Geometry *geometry in _geometries)
        [geometry uploadToBuffers];

    MTLResourceOptions options = getManagedBufferStorageMode();

    _lightBuffer = [_device newBufferWithLength:_lights.size() * sizeof(AreaLight) options:options];

    memcpy(_lightBuffer.contents, &_lights[0], _lightBuffer.length);

#if !TARGET_OS_IPHONE
    [_lightBuffer didModifyRange:NSMakeRange(0, _lightBuffer.length)];
#endif
}

+ (Scene *)newMotionBlurSceneWithDevice:(id <MTLDevice>)device
                     usePrimitiveMotion:(BOOL)usePrimitiveMotion
{
    Scene *scene = [[Scene alloc] initWithDevice:device];

    // Set up the camera.
    scene.cameraPosition = vector3(0.0f, 1.0f, 3.42f);
    scene.cameraTarget = vector3(0.0f, 1.0f, 0.0f);
    scene.cameraUp = vector3(0.0f, 1.0f, 0.0f);
    
    // Create a single keyframe of triangle data for the light source.
    TriangleKeyframeData *lightKeyframeData = [[TriangleKeyframeData alloc] initWithDevice:device];

    Geometry *lightMesh = [[Geometry alloc] initWithKeyframes:@[ lightKeyframeData ]];

    [scene addGeometry:lightMesh];

    matrix_float4x4 transform = matrix4x4_translation(0.0f, 1.0f, 0.0f) * matrix4x4_scale(0.5f, 1.98f, 0.5f);

    // Add the light source geometry to the keyframe.
    [lightKeyframeData addCubeWithFaces:FACE_MASK_POSITIVE_Y
                                  color:vector3(1.0f, 1.0f, 1.0f)
                              transform:transform
                          inwardNormals:true];
    
    // Create a single keyframe of triangle data for the Cornell box.
    TriangleKeyframeData *cornellBoxKeyframeData = [[TriangleKeyframeData alloc] initWithDevice:device];

    Geometry *cornellBoxMesh = [[Geometry alloc] initWithKeyframes:@[ cornellBoxKeyframeData ]];

    [scene addGeometry:cornellBoxMesh];

    transform = matrix4x4_translation(0.0f, 1.0f, 0.0f) * matrix4x4_scale(2.0f, 2.0f, 2.0f);

    // Add the top, bottom, and back walls.
    [cornellBoxKeyframeData addCubeWithFaces:FACE_MASK_NEGATIVE_Y | FACE_MASK_POSITIVE_Y | FACE_MASK_NEGATIVE_Z
                                       color:vector3(0.725f, 0.71f, 0.68f)
                                   transform:transform
                               inwardNormals:true];

    // Add the left wall.
    [cornellBoxKeyframeData addCubeWithFaces:FACE_MASK_NEGATIVE_X
                                       color:vector3(0.63f, 0.065f, 0.05f)
                                   transform:transform
                               inwardNormals:true];

    // Add the right wall.
    [cornellBoxKeyframeData addCubeWithFaces:FACE_MASK_POSITIVE_X
                                       color:vector3(0.14f, 0.45f, 0.091f)
                                   transform:transform
                               inwardNormals:true];

    transform = matrix4x4_translation(-0.335f, 0.6f, -0.29f) *
                matrix4x4_rotation(0.3f, vector3(0.0f, 1.0f, 0.0f)) *
                matrix4x4_scale(0.6f, 1.2f, 0.6f);
    
    // Create a single keyframe of triangle data for the Ninja
    // character the renderer animates using instance motion.
    TriangleKeyframeData *staticNinjaKeyframeData = [[TriangleKeyframeData alloc] initWithDevice:device];

    Geometry *staticNinjaGeometry = [[Geometry alloc] initWithKeyframes:@[ staticNinjaKeyframeData ]];
        
    [scene addGeometry:staticNinjaGeometry];

    // Load the Ninja vertex data into the keyframe.
    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"ninja_0" withExtension:@"obj"];
        
    [staticNinjaKeyframeData addGeometryWithURL:URL];
    
    Geometry *animatedNinjaGeometry = nil;
    if(usePrimitiveMotion)
    {
        // Create two keyframes of triangle data for the Ninja character the renderer
        // animates using primitive motion.
        TriangleKeyframeData *animatedNinjaKeyframe0Data = [[TriangleKeyframeData alloc] initWithDevice:device];
        TriangleKeyframeData *animatedNinjaKeyframe1Data = [[TriangleKeyframeData alloc] initWithDevice:device];

        // Create a `Geometry` with two triangle keyframes.
         animatedNinjaGeometry = [[Geometry alloc] initWithKeyframes:@[
            animatedNinjaKeyframe0Data, animatedNinjaKeyframe1Data
        ]];

        [scene addGeometry:animatedNinjaGeometry];

        // Load one model into the first keyframe.
        [animatedNinjaKeyframe0Data addGeometryWithURL:URL];

        // Load a second model into the second keyframe. Metal interpolates between these two models.
        URL = [[NSBundle mainBundle] URLForResource:@"ninja_1" withExtension:@"obj"];

        [animatedNinjaKeyframe1Data addGeometryWithURL:URL];
    }
    
    // Create instances.
    transform = matrix_identity_float4x4;

    // Create an instance of the light.
    GeometryInstance *lightMeshInstance = [[GeometryInstance alloc] initWithGeometry:lightMesh
                                                                           transform:transform
                                                                                mask:GEOMETRY_MASK_LIGHT];

    [scene addInstance:lightMeshInstance];

    // Create an instance of the Cornell Box.
    GeometryInstance *cornellBoxMeshInstance = [[GeometryInstance alloc] initWithGeometry:cornellBoxMesh
                                                                                transform:transform
                                                                                     mask:GEOMETRY_MASK_TRIANGLE];

    [scene addInstance:cornellBoxMeshInstance];
    
    // Create an instance of the Ninja character and animate it using instance motion. The
    // kernel achieves the motion blur effect by providing two transformation matrices, one
    // for each keyframe.
    matrix_float4x4 transforms[2];
    
    transform = matrix4x4_translation(-0.45f, 0.0f, 1.0f) * matrix4x4_scale(0.2f, 0.2f, 0.2f);
    
    transforms[0] = transform;
    transforms[1] = matrix_multiply(matrix4x4_translation(0, 0.0, -2.0), transform);

    GeometryInstance *leftNinjaGeometryInstance = [[GeometryInstance alloc] initWithGeometry:staticNinjaGeometry
                                                                                  transforms:transforms
                                                                 instanceMotionKeyframeCount:2
                                                                                        mask:GEOMETRY_MASK_TRIANGLE];
    
    [scene addInstance:leftNinjaGeometryInstance];

    transform = matrix4x4_translation(0.5f, 0.0f, 0.0f) * matrix4x4_scale(0.2f, 0.2f, 0.2f);
    
    // Create an instance of the Ninja character.
    GeometryInstance *rightNinjaGeometryInstance = [[GeometryInstance alloc] initWithGeometry:usePrimitiveMotion ? animatedNinjaGeometry : staticNinjaGeometry
                                                                                    transform:transform
                                                                                         mask:GEOMETRY_MASK_TRIANGLE];

    [scene addInstance:rightNinjaGeometryInstance];

    // Add a light.
    AreaLight light;

    light.position = vector3(0.0f, 1.98f, 0.0f);
    light.forward = vector3(0.0f, -1.0f, 0.0f);
    light.right = vector3(0.25f, 0.0f, 0.0f);
    light.up = vector3(0.0f, 0.0f, 0.25f);
    light.color = vector3(4.0f, 4.0f, 4.0f);

    [scene addLight:light];

    return scene;
}

@end
