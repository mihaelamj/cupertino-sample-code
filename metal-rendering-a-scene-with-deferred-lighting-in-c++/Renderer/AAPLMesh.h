/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for mesh and submesh objects used for managing models.
*/
#ifndef Mesh_h
#define Mesh_h
#include <Metal/Metal.hpp>
#include <unordered_map>

#include "AAPLShaderTypes.h"
#include <vector>
#include <array>

constexpr uint8_t kSubmeshTextureCount = 3;
using SubmeshTextureArray = std::array< MTL::Texture*, kSubmeshTextureCount >;

struct MeshVertex
{
    vector_float3 position;
    vector_float2 texcoord;
    vector_float3 normal;
    vector_float3 tangent;
    vector_float3 bitangent;
};

class MeshBuffer
{
public:

    MeshBuffer();
    
    /// Creates a mesh buffer instance that owns the buffer memory.
    MeshBuffer(MTL::Buffer* pBuffer,
               NS::UInteger offset,
               NS::UInteger length,
               NS::UInteger argumentIndex = NS::UIntegerMax);

    MeshBuffer(const MeshBuffer& rhs);
    MeshBuffer& operator=(MeshBuffer& rhs);

    MeshBuffer(MeshBuffer&& rhs);
    MeshBuffer& operator=(MeshBuffer&& rhs);

    ~MeshBuffer();

    MTL::Buffer* buffer() const;
    NS::UInteger length() const;
    NS::UInteger argumentIndex() const;
    NS::UInteger offset() const;

    static std::vector<MeshBuffer>
    makeVertexBuffers(MTL::Device* pDevice,
                      const MTL::VertexDescriptor* pDescriptor,
                      NS::UInteger vertexCount,
                      NS::UInteger indexBufferSize);

private:

    MTL::Buffer* m_pBuffer;
    NS::UInteger m_length;
    NS::UInteger m_offset;
    NS::UInteger m_argumentIndex;
};


// An app-specific submesh type that contains the data to draw its part of the larger mesh.
struct Submesh final
{
public:

    Submesh();
    
    Submesh(MTL::PrimitiveType  primitiveType,
            MTL::IndexType      indexType,
            NS::UInteger        indexCount,
            const MeshBuffer&   indexBuffer,
            const SubmeshTextureArray& pTextures);

    Submesh(MTL::PrimitiveType  primitiveType,
            MTL::IndexType      indexType,
            NS::UInteger        indexCount,
            const MeshBuffer&   indexBuffer);

    Submesh(const Submesh& rhs);
    Submesh& operator=(Submesh& rhs);
    
    Submesh(Submesh&& rhs);
    Submesh& operator=(Submesh&& rhs);
    
    ~Submesh();
    
    MTL::PrimitiveType  primitiveType() const;
    MTL::IndexType      indexType() const;
    NS::UInteger        indexCount() const;
    const MeshBuffer&   indexBuffer() const;
    const SubmeshTextureArray& textures() const;

private:

    MTL::PrimitiveType m_primitiveType;

    MTL::IndexType m_indexType;

    NS::UInteger m_indexCount;

    MeshBuffer m_indexBuffer;

    SubmeshTextureArray m_pTextures;
};

struct Mesh
{
public:

    Mesh();

    Mesh(const std::vector<Submesh> & submeshes,
         const std::vector<MeshBuffer> & vertexBuffers);

    Mesh(const Submesh & submesh,
         const std::vector<MeshBuffer> & vertexBuffers);

    Mesh(const Mesh& rhs);
    Mesh& operator=(const Mesh& rhs);

    Mesh(Mesh&& rhs);
    Mesh& operator=(Mesh&& rhs);

    virtual ~Mesh();

    const std::vector<Submesh> & submeshes() const;

    const std::vector<MeshBuffer> & vertexBuffers() const;

private:

    std::vector<Submesh> m_submeshes;

    std::vector<MeshBuffer> m_vertexBuffers;
};

std::vector<Mesh> newMeshesFromBundlePath(const char* bundlePath,
                                          MTL::Device* pDevice,
                                          const MTL::VertexDescriptor& vertexDescriptor,
                                          NS::Error **pError);


Mesh makeSphereMesh(MTL::Device* pDevice,
                    const MTL::VertexDescriptor& vertexDescriptor,
                    int radialSegments, int verticalSegments, float radius);

Mesh makeIcosahedronMesh(MTL::Device* pDevice,
                         const MTL::VertexDescriptor& vertexDescriptor,
                         float radius);

MTL::Texture* newTextureFromCatalog( MTL::Device* pDevice, const char* name, MTL::StorageMode storageMode, MTL::TextureUsage usage );

#pragma mark - MeshBuffer inline implementations

inline MTL::Buffer* MeshBuffer::buffer() const
{
    return m_pBuffer;
}

inline NS::UInteger MeshBuffer::offset() const
{
    return m_offset;
}

inline NS::UInteger MeshBuffer::length() const
{
    return m_length;
}

inline NS::UInteger MeshBuffer::argumentIndex() const
{
    return m_argumentIndex;
}

#pragma mark - Submesh inline implementations

inline MTL::PrimitiveType Submesh::primitiveType() const
{
    return m_primitiveType;
}

inline MTL::IndexType Submesh::indexType() const
{
    return m_indexType;
}

inline NS::UInteger Submesh::indexCount() const
{
    return m_indexCount;
}

inline const MeshBuffer& Submesh::indexBuffer() const
{
    return m_indexBuffer;
}

#pragma mark - Mesh inline implementations

inline const SubmeshTextureArray& Submesh::textures() const
{
    return m_pTextures;
}

inline const std::vector<Submesh>& Mesh::submeshes() const
{
    return m_submeshes;
}

inline const std::vector<MeshBuffer>& Mesh::vertexBuffers() const
{
    return m_vertexBuffers;
}

#endif // Mesh_h
