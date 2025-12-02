/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The MSL source for the app's vertex, fragment, and mesh shaders.
*/

#include <metal_stdlib>

#if __METAL_VERSION__ < 300

void meshShaderObjectStageFunction();
void meshShaderMeshStageFunctionPoints();
void meshShaderMeshStageFunctionLines();
void meshShaderMeshStageFunctionTriangles();

fragment float4 fragmentShader()
{
    return float4(1.0f);
}

#else

#include "AAPLShaderTypes.h"

constant int AAPLTopologyChoice [[function_constant(AAPL_FUNCTION_CONSTANT_TOPOLOGY)]];

using namespace metal;

struct vertexOut
{
    float4 position [[position]];
    float3 normal;
};

struct pointVertexOut
{
    float4 position [[position]];
    float3 normal;
    float size [[point_size]] { 5 };
};

struct payload_t
{
    AAPLVertex vertices[AAPLMaxMeshletVertexCount];
    float4x4 transform;
    float3 color;
    uint8_t lod;
    uint32_t primitiveCount;
    uint8_t vertexCount;

    /// The array of vertex indices for the meshlet into the vertices array.
    ///
    /// The object stage uses this to copy indices into the payload.
    /// The mesh stage uses this to set the indices for the geometry.
    uint8_t indices[1024];
};

// Per-vertex primitive data.
struct primOut
{
    float3 color;
};

struct fragmentIn
{
    vertexOut v;
    primOut p;
};

/// Defines a mesh declaration type that supports points.
using AAPLPointMeshType = metal::mesh<pointVertexOut, primOut, AAPLMaxMeshletVertexCount, AAPLMaxMeshletVertexCount, metal::topology::point>;

/// Defines a mesh declaration type that supports lines.
using AAPLLineMeshType = metal::mesh<vertexOut, primOut, AAPLMaxMeshletVertexCount, (AAPLNumPatchSegmentsX-1)*(AAPLNumPatchSegmentsY-1)*4, metal::topology::line>;

/// Defines a mesh declaration type that supports triangles.
using AAPLTriangleMeshType = metal::mesh<vertexOut, primOut, AAPLMaxMeshletVertexCount, AAPLMaxPrimitiveCount, metal::topology::triangle>;

/// The object stage that generates one submesh group.
[[object, max_total_threads_per_threadgroup(AAPLMaxTotalThreadsPerObjectThreadgroup), max_total_threadgroups_per_mesh_grid(AAPLMaxThreadgroupsPerMeshGrid)]]
void meshShaderObjectStageFunction(object_data payload_t& payload            [[payload]],
                                   mesh_grid_properties meshGridProperties,
                                   constant AAPLMeshInfo* meshes             [[buffer(AAPLBufferIndexMeshInfo)]],
                                   constant AAPLVertex* vertices             [[buffer(AAPLBufferIndexMeshVertices)]],
                                   constant AAPLIndexType* indices           [[buffer(AAPLBufferIndexMeshIndices)]],
                                   constant float4x4*   transforms           [[buffer(AAPLBufferIndexTransforms)]],
                                   constant float3*     colors               [[buffer(AAPLBufferIndexMeshColor)]],
                                   constant float4x4&   viewProjectionMatrix [[buffer(AAPLBufferViewProjectionMatrix)]],
                                   constant uint&       lod                  [[buffer(AAPLBufferIndexLODChoice)]],
                                   uint3                positionInGrid       [[threadgroup_position_in_grid]])
{
    // threadIndex is the object index.
    uint threadIndex = (AAPLNumObjectsXY * positionInGrid.z) + (AAPLNumObjectsX * positionInGrid.y) + positionInGrid.x;
    if (threadIndex >= AAPLNumObjectsXYZ || threadIndex >= 1024)
        return;
    
    constant AAPLMeshInfo& meshInfo = meshes[threadIndex];
    
    payload.lod = 0;
    payload.color = colors[threadIndex];
    
    uint startIndex = meshInfo.lod1.startIndex;
    uint startVertexIndex = meshInfo.lod1.startVertexIndex;
    
    // Adjust parameters if using a lower level of detail.
    if (lod == 0)
    {
        payload.primitiveCount = meshInfo.lod1.primitiveCount;
        payload.vertexCount = meshInfo.lod1.vertexCount;
    }
    else if (lod == 1)
    {
        // Choose LOD 1.
        startIndex = meshInfo.lod2.startIndex;
        startVertexIndex = meshInfo.lod2.startVertexIndex;
        payload.primitiveCount = meshInfo.lod2.primitiveCount;
        payload.vertexCount = meshInfo.lod2.vertexCount;
    }
    else if (lod == 2)
    {
        // Choose LOD 2.
        startIndex = meshInfo.lod3.startIndex;
        startVertexIndex = meshInfo.lod3.startVertexIndex;
        payload.primitiveCount = meshInfo.lod3.primitiveCount;
        payload.vertexCount = meshInfo.lod3.vertexCount;
    }

    // Copy the triangle indices into the payload.
    for (uint i = 0; i < payload.primitiveCount*3; i++)
    {
        payload.indices[i] = indices[startIndex + i];
    }

    // Copy the vertex data into the payload.
    for (size_t i = 0; i < payload.vertexCount; i++)
    {
        payload.vertices[i] = vertices[startVertexIndex + i];
    }
    
    // Concatenate the view projection matrix to the model transform matrix.
    payload.transform = viewProjectionMatrix * transforms[threadIndex];

    // Set the output submesh count for the mesh shader.
    // Because the mesh shader is only producing one mesh, the threadgroup grid size is 1 x 1 x 1.
    meshGridProperties.set_threadgroups_per_grid(uint3(1, 1, 1));
}

/// The mesh stage function that generates a point mesh.
[[mesh, max_total_threads_per_threadgroup(AAPLMaxTotalThreadsPerMeshThreadgroup)]]
void meshShaderMeshStageFunctionPoints(AAPLPointMeshType output,
                                       const object_data payload_t& payload [[payload]],
                                       uint lid [[thread_index_in_threadgroup]],
                                       uint tid [[threadgroup_position_in_grid]])
{
    // Set the number of primitives for the entire mesh.
    output.set_primitive_count(payload.vertexCount);
    
    // Apply the transformation matrix to all the vertex data.
    // For performance, place the vertices common to all LODs in the first part of the buffer and then limit the vertex count.
    if (lid < payload.vertexCount)
    {
        pointVertexOut v;
        float4 position = float4(payload.vertices[lid].position.xyz, 1.0f);
        v.normal = float3(0, 0, 1);
        v.position = payload.transform * position;
        output.set_vertex(lid, v);
        primOut p;
        p.color = payload.color;
        output.set_primitive(lid, p);
        output.set_index(lid, lid);
    }
}

/// The mesh stage function that generates a line mesh.
[[mesh, max_total_threads_per_threadgroup(AAPLMaxTotalThreadsPerMeshThreadgroup)]]
void meshShaderMeshStageFunctionLines(AAPLLineMeshType output,
                                      const object_data payload_t& payload [[payload]],
                                      uint lid [[thread_index_in_threadgroup]])
{
    // Calculate the number of primitives to generate a mesh of lines that outline the quads.
    // The input payload is ordered as pairs of triangles, so divide by two.
    // The number of lines per primitive is four (a quad).
    uint MaxPrimitives = payload.primitiveCount/2;
    constexpr uint LinesPerPrimitive = 4;
    
    // Set the number of primitives for the entire mesh.
    output.set_primitive_count(MaxPrimitives * LinesPerPrimitive);
    
    // Apply the transformation matrix to all the vertex data.
    // For performance, place the vertices common to all LODs in the first part of the buffer and then limit the vertex count.
    if (lid < payload.vertexCount)
    {
        vertexOut v;
        float4 position = float4(payload.vertices[lid].position.xyz, 1.0f);
        v.position = payload.transform * position;
        v.normal = normalize(payload.vertices[lid].normal.xyz);
        output.set_vertex(lid, v);     
    }
    
    // Set the constant data for the entire primitive.
    if (lid < MaxPrimitives)
    {
        primOut p;
        p.color = payload.color;
        uint pid = LinesPerPrimitive*lid;
        output.set_primitive(pid+0, p);
        output.set_primitive(pid+1, p);
        output.set_primitive(pid+2, p);
        output.set_primitive(pid+3, p);

        // Set the output index.
        uint i = (2*LinesPerPrimitive*lid);
        // There are six vertices per quad.
        uint j = (6*lid);
        uint j1 = payload.indices[j+0];
        uint j2 = payload.indices[j+2];
        uint j3 = payload.indices[j+4];
        uint j4 = payload.indices[j+3];
        output.set_index(i+0, j1);
        output.set_index(i+1, j2);
        output.set_index(i+2, j2);
        output.set_index(i+3, j3);
        output.set_index(i+4, j3);
        output.set_index(i+5, j4);
        output.set_index(i+6, j4);
        output.set_index(i+7, j1);
    }
}

/// The mesh stage function that generates a triangle mesh.
[[mesh, max_total_threads_per_threadgroup(AAPLMaxTotalThreadsPerMeshThreadgroup)]]
void meshShaderMeshStageFunction(AAPLTriangleMeshType output,
                                 const object_data payload_t& payload [[payload]],
                                 uint lid [[thread_index_in_threadgroup]],
                                 uint tid [[threadgroup_position_in_grid]])
{
    // Set the number of primitives for the entire mesh.
    output.set_primitive_count(payload.primitiveCount);
    
    // Apply the transformation matrix to all the vertex data.
    // For performance, place the vertices common to all LODs in the first part of the buffer and then limit the vertex count.
    if (lid < payload.vertexCount)
    {
        vertexOut v;
        float4 position = float4(payload.vertices[lid].position.xyz, 1.0f);
        v.position = payload.transform * position;
        v.normal = normalize(payload.vertices[lid].normal.xyz);
        output.set_vertex(lid, v);
    }
    
    // Set the constant data for the entire primitive.
    if (lid < payload.primitiveCount)
    {
        primOut p;
        p.color = payload.color;
        output.set_primitive(lid, p);

        // Set the output indices.
        uint i = (3*lid);
        output.set_index(i+0, payload.indices[i+0]);
        output.set_index(i+1, payload.indices[i+1]);
        output.set_index(i+2, payload.indices[i+2]);
    }
}

/// The fragment shader that blends a bit of Lambertian light with the meshlet's normal and mesh color.
fragment float4 fragmentShader(fragmentIn in [[stage_in]])
{
    float3 N = normalize(in.v.normal);
    float3 L = normalize(float3(1, 1, 1));

    // The dot product of the normal and light direction isn't clamped and makes
    // the intensity of the mesh color range between `0.5` and `1.0`.
    float3 ambientIntensity = float3(1.0);
    float3 lightIntensity = float3(100.0);
    float3 colorIntensity = ambientIntensity + lightIntensity * (0.5 + 0.5 * dot(N, L));

    // Reduce the dynamic range by a simple tone-mapping operator.
    colorIntensity = colorIntensity / (1.0 + colorIntensity);

    // Change the range of the normal from [-1, 1] to [0, 1] to use it as a color.
    float3 normalColor = N * 0.5 + 0.5;

    // Add a 20% mix of the normal color with the shaded meshlet color.
    return float4(mix(colorIntensity * in.p.color, normalColor, 0.2), 1.0f);
}

#endif
