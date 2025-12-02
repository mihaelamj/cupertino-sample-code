/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of class with utilities for debuging rendering.
*/

#import "AAPLDebugRender.h"

#if ENABLE_DEBUG_RENDERING
#import "AAPLShaderTypes.h"

#import <Metal/Metal.h>
#import <vector>

using namespace simd;

// Internal structure to define a mesh for debug rendering.
struct AAPLDebugMesh
{
    // CPU mesh data.
    std::vector<simd::float3> positions;
    std::vector<uint16_t> indices;

    // GPU copy of mesh data.
    id<MTLBuffer> vb;
    id<MTLBuffer> ib;
};

static AAPLDebugMesh createDebugCone(id<MTLDevice> device)
{
    const unsigned sliceCount = 16;
    const float radius = 1.0f;
    const float height = 1.0f;

    AAPLDebugMesh mesh;

    float dTheta = 2.0f * M_PI / sliceCount;

    for (int i = 0; i <= sliceCount; i++)
    {
        float x = radius * cos(i * dTheta);
        float z = radius * sin(i * dTheta);

        mesh.positions.push_back(simd::make_float3(x, height, z));
    }
    mesh.positions.push_back(simd::make_float3(0, 0, 0));
    uint16_t centerIndex = mesh.positions.size() - 1;
    for (int i = 0; i < sliceCount; i++)
    {
        mesh.indices.push_back(centerIndex);
        mesh.indices.push_back(i);
        mesh.indices.push_back(i + 1);
    }

    mesh.vb = [device newBufferWithLength:mesh.positions.size() * sizeof(simd::float3) options:MTLResourceStorageModeShared];
    mesh.vb.label = @"Debug Cone VB";
    mesh.ib = [device newBufferWithLength:mesh.indices.size() * sizeof(uint16_t) options:MTLResourceStorageModeShared];
    mesh.ib.label = @"Debug Cone IB";

    memcpy(mesh.vb.contents, mesh.positions.data(), mesh.positions.size() * sizeof(simd::float3));
    memcpy(mesh.ib.contents, mesh.indices.data(), mesh.indices.size() * sizeof(uint16_t));

    return mesh;
}

static AAPLDebugMesh createDebugSphere(id<MTLDevice> device)
{
    const unsigned stackCount = 16;
    const unsigned sliceCount = 16;
    const float radius = 1.0f;

    AAPLDebugMesh mesh;

    mesh.positions.push_back(vector3(0.f, radius, 0.f));

    float phiStep = M_PI/stackCount;
    float thetaStep = 2.0f*M_PI/sliceCount;

    for (int i = 1; i <= stackCount-1; i++)
    {
        float phi = i*phiStep;
        for (int j = 0; j <= sliceCount; j++)
        {
            float theta = j*thetaStep;
            simd::float3 p = (simd::float3){radius*sin(phi)*cos(theta),
                radius*cos(phi),
                radius*sin(phi)*sin(theta)};

            mesh.positions.push_back(p);
        }
    }

    mesh.positions.push_back(vector3(0.f, -radius, 0.f));

    for (int i = 1; i <= sliceCount; i++)
    {
        mesh.indices.push_back(0);
        mesh.indices.push_back(i+1);
        mesh.indices.push_back(i);
    }
    uint32_t baseIndex = 1;
    uint32_t ringVertexCount = sliceCount + 1;
    for (int i = 0; i < stackCount-2; i++)
    {
        for (int j = 0; j < sliceCount; j++)
        {
            mesh.indices.push_back(baseIndex + i*ringVertexCount + j);
            mesh.indices.push_back(baseIndex + i*ringVertexCount + j+1);
            mesh.indices.push_back(baseIndex + (i+1)*ringVertexCount + j);

            mesh.indices.push_back(baseIndex + (i+1)*ringVertexCount + j);
            mesh.indices.push_back(baseIndex + i*ringVertexCount + j+1);
            mesh.indices.push_back(baseIndex + (i+1)*ringVertexCount + j + 1);
        }
    }

    uint32_t southPoleIndex = (uint32_t)mesh.positions.size() - 1;
    baseIndex = southPoleIndex - ringVertexCount;
    for (int i = 0; i < sliceCount; i++)
    {
        mesh.indices.push_back(southPoleIndex);
        mesh.indices.push_back(baseIndex+i);
        mesh.indices.push_back(baseIndex+i+1);
    }

    mesh.vb = [device newBufferWithLength:mesh.positions.size() * sizeof(simd::float3) options:MTLResourceStorageModeShared];
    mesh.vb.label = @"Debug Sphere VB";
    mesh.ib = [device newBufferWithLength:mesh.indices.size() * sizeof(uint16_t) options:MTLResourceStorageModeShared];
    mesh.ib.label = @"Debug Sphere IB";

    memcpy(mesh.vb.contents, mesh.positions.data(), mesh.positions.size() * sizeof(simd::float3));
    memcpy(mesh.ib.contents, mesh.indices.data(), mesh.indices.size() * sizeof(uint16_t));

    return mesh;
}

static AAPLDebugMesh createDebugCube(id<MTLDevice> device)
{
    AAPLDebugMesh mesh;

    mesh.positions =
    {
        vector3(-0.5f, -0.5f, -0.5f),
        vector3( 0.5f, -0.5f, -0.5f),
        vector3(-0.5f,  0.5f, -0.5f),
        vector3( 0.5f,  0.5f, -0.5f),
        vector3(-0.5f, -0.5f,  0.5f),
        vector3( 0.5f, -0.5f,  0.5f),
        vector3(-0.5f,  0.5f,  0.5f),
        vector3( 0.5f,  0.5f,  0.5f),
    };

    mesh.indices.push_back(0);
    mesh.indices.push_back(4);
    mesh.indices.push_back(6);
    mesh.indices.push_back(0);
    mesh.indices.push_back(6);
    mesh.indices.push_back(2);

    mesh.indices.push_back(1);
    mesh.indices.push_back(3);
    mesh.indices.push_back(7);
    mesh.indices.push_back(1);
    mesh.indices.push_back(7);
    mesh.indices.push_back(5);

    mesh.indices.push_back(0);
    mesh.indices.push_back(1);
    mesh.indices.push_back(5);
    mesh.indices.push_back(0);
    mesh.indices.push_back(5);
    mesh.indices.push_back(4);

    mesh.indices.push_back(2);
    mesh.indices.push_back(6);
    mesh.indices.push_back(7);
    mesh.indices.push_back(2);
    mesh.indices.push_back(7);
    mesh.indices.push_back(3);

    mesh.indices.push_back(0);
    mesh.indices.push_back(2);
    mesh.indices.push_back(3);
    mesh.indices.push_back(0);
    mesh.indices.push_back(3);
    mesh.indices.push_back(1);

    mesh.indices.push_back(4);
    mesh.indices.push_back(5);
    mesh.indices.push_back(7);
    mesh.indices.push_back(4);
    mesh.indices.push_back(7);
    mesh.indices.push_back(6);

    mesh.vb = [device newBufferWithLength:mesh.positions.size() * sizeof(simd::float3) options:MTLResourceStorageModeShared];
    mesh.ib = [device newBufferWithLength:mesh.indices.size() * sizeof(uint16_t) options:MTLResourceStorageModeShared];

    memcpy(mesh.vb.contents, mesh.positions.data(), mesh.positions.size() * sizeof(simd::float3));
    mesh.vb.label = @"Debug Cube VB";
    memcpy(mesh.ib.contents, mesh.indices.data(), mesh.indices.size() * sizeof(uint16_t));
    mesh.ib.label = @"Debug Cube IB";

    return mesh;
}

//------------------------------------------------------------------------------

// Internal structure to track instances to be rendered by AAPLDebugRender renderInstances.
struct AAPLDebugInstance
{
    float4x4 worldMatrix;
    float4 color;
};

//------------------------------------------------------------------------------

@implementation AAPLDebugRender
{
    // Device from initialization.
    id<MTLDevice> _device;

    AAPLDebugMesh _sphereMesh;
    AAPLDebugMesh _coneMesh;
    AAPLDebugMesh _cubeMesh;

    // Vectors of instances to be rendered on the next renderInstances call.
    std::vector<AAPLDebugInstance> _sphereInstances;
    std::vector<AAPLDebugInstance> _sphereWireframeInstances;

    std::vector<AAPLDebugInstance> _cubeInstances;
    std::vector<AAPLDebugInstance> _cubeWireframeInstances;

    std::vector<AAPLDebugInstance> _coneInstances;
    std::vector<AAPLDebugInstance> _coneWireframeInstances;
}

- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
{
    self = [super init];
    if(self)
    {
        _device = device;

        _sphereMesh = createDebugSphere(_device);
        _coneMesh = createDebugCone(_device);
        _cubeMesh = createDebugCube(_device);
    }

    return self;
}

- (void)renderDebugMesh:(const AAPLDebugMesh&)mesh
         viewProjMatrix:(matrix_float4x4)viewProjectionMatrix
            worldMatrix:(matrix_float4x4)worldMatrix
                  color:(simd::float4)color
              onEncoder:(id <MTLRenderCommandEncoder>)renderEncoder
{
    matrix_float4x4 wvpMatrix = viewProjectionMatrix * worldMatrix;

    [renderEncoder setVertexBytes:&wvpMatrix length:sizeof(wvpMatrix) atIndex:AAPLBufferIndexCameraParams];
    [renderEncoder setVertexBuffer:mesh.vb offset:0 atIndex:AAPLBufferIndexVertexMeshPositions];

    [renderEncoder setFragmentBytes:&color length:sizeof(color) atIndex:AAPLBufferIndexFragmentMaterial];

    [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                              indexCount:mesh.indices.size()
                               indexType:MTLIndexTypeUInt16
                             indexBuffer:mesh.ib
                       indexBufferOffset:0];
}

- (void)renderInstances:(nonnull id <MTLRenderCommandEncoder>)renderEncoder
         viewProjMatrix:(matrix_float4x4)viewProjMatrix
{
    for(AAPLDebugInstance& inst : _sphereInstances)
    {
        [self renderDebugMesh:_sphereMesh
               viewProjMatrix:viewProjMatrix
                  worldMatrix:inst.worldMatrix
                        color:inst.color
                    onEncoder:renderEncoder];
    }

    _sphereInstances.clear();

    for(AAPLDebugInstance& inst : _cubeInstances)
    {
        [self renderDebugMesh:_cubeMesh
               viewProjMatrix:viewProjMatrix
                  worldMatrix:inst.worldMatrix
                        color:inst.color
                    onEncoder:renderEncoder];
    }

    _cubeInstances.clear();

    for(AAPLDebugInstance& inst : _coneInstances)
    {
        [self renderDebugMesh:_coneMesh
               viewProjMatrix:viewProjMatrix
                  worldMatrix:inst.worldMatrix
                        color:inst.color
                    onEncoder:renderEncoder];
    }

    _coneInstances.clear();

    [renderEncoder setTriangleFillMode:MTLTriangleFillModeLines];

    for(AAPLDebugInstance& inst : _sphereWireframeInstances)
    {
        [self renderDebugMesh:_sphereMesh
               viewProjMatrix:viewProjMatrix
                  worldMatrix:inst.worldMatrix
                        color:inst.color
                    onEncoder:renderEncoder];
    }

    _sphereWireframeInstances.clear();

    for(AAPLDebugInstance& inst : _cubeWireframeInstances)
    {
        [self renderDebugMesh:_cubeMesh
               viewProjMatrix:viewProjMatrix
                  worldMatrix:inst.worldMatrix
                        color:inst.color
                    onEncoder:renderEncoder];
    }

    _cubeWireframeInstances.clear();

    for(AAPLDebugInstance& inst : _coneWireframeInstances)
    {
        [self renderDebugMesh:_coneMesh
               viewProjMatrix:viewProjMatrix
                  worldMatrix:inst.worldMatrix
                        color:inst.color
                    onEncoder:renderEncoder];
    }

    _coneWireframeInstances.clear();

    [renderEncoder setTriangleFillMode:MTLTriangleFillModeFill];
}

- (void)renderSphereAt:(simd::float3)position
                radius:(float)radius
                 color:(simd::float4)color
             wireframe:(bool)wireframe
{
    matrix_float4x4 worldMatrix = {
        .columns[0] = { radius, 0.0f, 0.0f, 0.0f },
        .columns[1] = { 0.0f, radius, 0.0f, 0.0f },
        .columns[2] = { 0.0f, 0.0f, radius, 0.0f },
        .columns[3] = { position.x, position.y, position.z, 1.0f }
    };

    AAPLDebugInstance inst;
    inst.worldMatrix    = worldMatrix;
    inst.color          = color;

    if(wireframe)
        _sphereWireframeInstances.push_back(inst);
    else
        _sphereInstances.push_back(inst);
}

- (void)renderCubeAt:(simd::float4x4)worldMatrix
               color:(simd::float4)color
           wireframe:(bool)wireframe
{
    AAPLDebugInstance inst;
    inst.worldMatrix    = worldMatrix;
    inst.color          = color;

    if(wireframe)
        _cubeWireframeInstances.push_back(inst);
    else
        _cubeInstances.push_back(inst);
}

- (void)renderConeAt:(simd::float4x4)worldMatrix
               color:(simd::float4)color
           wireframe:(bool)wireframe
{
    AAPLDebugInstance inst;
    inst.worldMatrix    = worldMatrix;
    inst.color          = color;

    if(wireframe)
        _coneWireframeInstances.push_back(inst);
    else
        _coneInstances.push_back(inst);
}

@end

#endif
