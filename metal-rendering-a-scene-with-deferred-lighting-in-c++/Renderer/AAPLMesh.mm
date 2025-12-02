 /*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation for mesh and submesh objects.
*/
#include <MetalKit/MetalKit.h>
#include <ModelIO/ModelIO.h>
#include <set>
#include <unordered_map>

#include "AAPLMesh.h"

// Include the header shared between C code here, which executes Metal API commands, and .metal files.
#include "AAPLShaderTypes.h"
#include "AAPLUtilities.h"

#include <Metal/Metal.hpp>

#pragma mark - MeshBuffer Implementation

MeshBuffer::MeshBuffer()
: m_pBuffer( nullptr )
, m_offset( 0 )
, m_length( 0 )
, m_argumentIndex( 0 )
{
    
}

inline MeshBuffer::MeshBuffer(MTL::Buffer* pBuffer,
                              NS::UInteger offset,
                              NS::UInteger length,
                              NS::UInteger argumentIndex )
: m_pBuffer(pBuffer->retain())
, m_offset(offset)
, m_length(length)
, m_argumentIndex(argumentIndex)
{
    
}

MeshBuffer::MeshBuffer(const MeshBuffer& rhs)
: m_pBuffer( rhs.m_pBuffer->retain() )
, m_length( rhs.m_length )
, m_offset( rhs.m_offset )
, m_argumentIndex( rhs.m_argumentIndex )
{
    
}

MeshBuffer& MeshBuffer::operator=(MeshBuffer& rhs)
{
    m_pBuffer = rhs.m_pBuffer->retain();
    m_length = rhs.m_length;
    m_offset = rhs.m_offset;
    m_argumentIndex = rhs.m_argumentIndex;
    return *this;
}

MeshBuffer::MeshBuffer(MeshBuffer&& rhs)
: m_pBuffer( rhs.m_pBuffer->retain() )
, m_length( rhs.m_length )
, m_offset( rhs.m_offset )
, m_argumentIndex( rhs.m_argumentIndex )
{
    rhs.m_pBuffer->release();
    rhs.m_pBuffer = nullptr;
}

MeshBuffer& MeshBuffer::operator=(MeshBuffer&& rhs)
{
    m_pBuffer = rhs.m_pBuffer->retain();
    rhs.m_pBuffer->release();
    rhs.m_pBuffer = nullptr;
    
    m_length = rhs.m_length;
    m_offset = rhs.m_offset;
    m_argumentIndex = rhs.m_argumentIndex;
    return *this;
}

MeshBuffer::~MeshBuffer()
{
    m_pBuffer->release();
    m_pBuffer = nullptr;
}

#pragma mark - Submesh Implementation

Submesh::Submesh()
: m_primitiveType( MTL::PrimitiveTypeTriangle )
, m_indexType( MTL::IndexTypeUInt16 )
, m_indexCount( 0 )
, m_indexBuffer(nullptr, (NS::UInteger)0, (NS::UInteger)0)
{
    
}

Submesh::Submesh(MTL::PrimitiveType primitiveType,
                        MTL::IndexType indexType,
                        NS::UInteger indexCount,
                        const MeshBuffer& indexBuffer,
                        const SubmeshTextureArray& pTextures)
: m_primitiveType(primitiveType)
, m_indexType(indexType)
, m_indexCount(indexCount)
, m_indexBuffer(indexBuffer)
, m_pTextures( pTextures )
{
    for ( auto&& pTexture : m_pTextures )
    {
        pTexture->retain();
    }
}

// Initialize a submesh without textures
inline Submesh::Submesh(MTL::PrimitiveType primitiveType,
                        MTL::IndexType indexType,
                        NS::UInteger indexCount,
                        const MeshBuffer& indexBuffer)
: m_primitiveType(primitiveType)
, m_indexType(indexType)
, m_indexCount(indexCount)
, m_indexBuffer(indexBuffer)
{
    for ( size_t i = 0; i < 3; ++i )
    {
        m_pTextures[i] = nullptr;
    }
}

Submesh::Submesh(const Submesh& rhs)
: m_primitiveType( rhs.m_primitiveType )
, m_indexType( rhs.m_indexType )
, m_indexCount( rhs.m_indexCount )
, m_indexBuffer( rhs.m_indexBuffer )
, m_pTextures( rhs.m_pTextures )
{
    for ( size_t i = 0; i < 3; ++i )
    {
        m_pTextures[i]->retain();
    }
}

Submesh& Submesh::operator=(Submesh& rhs)
{
    m_primitiveType = rhs.m_primitiveType;
    m_indexType = rhs.m_indexType;
    m_indexCount = rhs.m_indexCount;
    m_indexBuffer = rhs.m_indexBuffer;
    m_pTextures = rhs.m_pTextures;
    
    for ( size_t i = 0; i < 3; ++i )
    {
        m_pTextures[i]->retain();
    }
    
    return *this;
}

Submesh::Submesh(Submesh&& rhs)
: m_primitiveType( rhs.m_primitiveType )
, m_indexType( rhs.m_indexType )
, m_indexCount( rhs.m_indexCount )
, m_indexBuffer( rhs.m_indexBuffer )
, m_pTextures( rhs.m_pTextures )
{
    for ( size_t i = 0; i < 3; ++i )
    {
        m_pTextures[i]->retain();
        rhs.m_pTextures[i]->release();
        rhs.m_pTextures[i] = nullptr;
    }
}

Submesh& Submesh::operator=(Submesh&& rhs)
{
    m_primitiveType = rhs.m_primitiveType;
    m_indexType = rhs.m_indexType;
    m_indexCount = rhs.m_indexCount;
    m_indexBuffer = rhs.m_indexBuffer;
    m_pTextures = rhs.m_pTextures;
    
    for ( size_t i = 0; i < 3; ++i )
    {
        m_pTextures[i]->retain();
        rhs.m_pTextures[i]->release();
        rhs.m_pTextures[i] = nullptr;
    }
    
    return *this;

}

Submesh::~Submesh()
{
    for ( auto&& pTexture : m_pTextures )
    {
        pTexture->release();
    }
}

#pragma mark - Mesh Implementation

Mesh::Mesh()
{
    // Construct a mesh with no submeshes and no `vertexBuffer`.
}


inline Mesh::Mesh(const std::vector<Submesh>& submeshes,
                  const std::vector<MeshBuffer>& vertexBuffers)
: m_submeshes(submeshes)
, m_vertexBuffers(vertexBuffers)
{
    
}


inline Mesh::Mesh(const Submesh& submesh,
                  const std::vector<MeshBuffer> & vertexBuffers)
: m_vertexBuffers(vertexBuffers)
{
    m_submeshes.emplace_back(submesh);
}

Mesh::Mesh(const Mesh& rhs)
: m_submeshes( rhs.m_submeshes)
, m_vertexBuffers( rhs.m_vertexBuffers )
{
    
}

Mesh& Mesh::operator=(const Mesh& rhs)
{
    m_submeshes = rhs.m_submeshes;
    m_vertexBuffers = rhs.m_vertexBuffers;
    return *this;
}

Mesh::Mesh(Mesh&& rhs)
: m_submeshes( rhs.m_submeshes)
, m_vertexBuffers( rhs.m_vertexBuffers )
{
    
}

Mesh& Mesh::operator=(Mesh&& rhs)
{
    m_submeshes = rhs.m_submeshes;
    m_vertexBuffers = rhs.m_vertexBuffers;
    return *this;
}

Mesh::~Mesh()
{
}

static MTL::Texture* createTextureFromMaterial(MDLMaterial * material,
                                         MDLMaterialSemantic materialSemantic,
                                         MTKTextureLoader* textureLoader)
{
    NSArray<MDLMaterialProperty *> *propertiesWithSemantic =
        [material propertiesWithSemantic:materialSemantic];

    for (MDLMaterialProperty *property in propertiesWithSemantic)
    {
        if(property.type == MDLMaterialPropertyTypeString ||
           property.type == MDLMaterialPropertyTypeURL)
        {
            // Load the textures with shader read using private storage
            NSDictionary<MTKTextureLoaderOption, id>* options = @{
                    MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate),
                    MTKTextureLoaderOptionTextureUsage : @(MTLTextureUsageShaderRead)
            };

            // Start by interpreting the string as a file path and attempt to load it with
            //    -[MTKTextureLoader newTextureWithContentsOfURL:options:error:]

            
            NSError* __autoreleasing err = nil;
            // Attempt to load the texture from the catalog by interpreting
            // the string as an asset catalog resource name
            
            MTL::Texture* pTexture = (__bridge_retained MTL::Texture*)
            [textureLoader newTextureWithName:property.stringValue
                                  scaleFactor:1.0
                                       bundle:nil
                                      options:options
                                        error:&err];
            
            // If the texture has been found for a material using the string as a file path name...
            if(pTexture)
            {
                // ...return it
                return pTexture;
            }

            // If no texture has been found by interpreting the URL as a path, attempt to load it
            // from the file system.

            pTexture = (__bridge_retained  MTL::Texture*)[textureLoader newTextureWithContentsOfURL:property.URLValue
                                                                                   options:options
                                                                                     error:&err];
            
            AAPL_ASSERT( !err, "Error loading texture:", property.URLValue );

            // If a texture is found by interpreting the URL as an asset catalog name return it.
            if( pTexture )
            {
                return pTexture;
            }

            // If did not find the texture in by interpreting it as a file path or as an asset name
            // in the asset catalog, something went wrong (Perhaps the file was missing or
            // misnamed in the asset catalog, model/material file, or file system)

            // Depending on how the Metal render pipeline use with this submesh is implemented,
            // this condition can be handled more gracefully.  The app could load a dummy texture
            // that will look okay when set with the pipeline or ensure that the pipelines
            // rendering this submesh do not require a material with this property.

            [NSException raise:@"Texture data for material property not found"
                        format:@"Requested material property semantic: %lu string: %@",
                                materialSemantic, property.stringValue];
        }
    }

    [NSException raise:@"No appropriate material property from which to create texture"
                format:@"Requested material property semantic: %lu", materialSemantic];

    return nullptr;
}

static Submesh createSubmesh(MDLSubmesh *modelIOSubmesh,
                             MTKSubmesh *metalKitSubmesh,
                             MTL::Device* pDevice,
                             MTKTextureLoader* textureLoader)
{

    // Set each index in the array with the appropriate material semantic specified in the
    //   submesh's material property

    // Create an array with three null textures that will be immediately replaced.
    SubmeshTextureArray textures;

    // Now that createSubmesh has added dummy elements, it can replace indices in the vector
    // with real textures.

    textures[TextureIndexBaseColor] = createTextureFromMaterial(modelIOSubmesh.material,
                                                                MDLMaterialSemanticBaseColor,
                                                                textureLoader);

    textures[TextureIndexSpecular]  = createTextureFromMaterial(modelIOSubmesh.material,
                                                               MDLMaterialSemanticSpecular,
                                                               textureLoader);

    textures[TextureIndexNormal]    = createTextureFromMaterial(modelIOSubmesh.material,
                                                                MDLMaterialSemanticTangentSpaceNormal,
                                                                textureLoader);

    MTL::Buffer* pMetalIndexBuffer = (__bridge_retained MTL::Buffer*)(metalKitSubmesh.indexBuffer.buffer);

    MeshBuffer indexBuffer(pMetalIndexBuffer, metalKitSubmesh.indexBuffer.offset, metalKitSubmesh.indexBuffer.length);

    Submesh submesh((MTL::PrimitiveType) metalKitSubmesh.primitiveType,
                    (MTL::IndexType) metalKitSubmesh.indexType,
                    metalKitSubmesh.indexCount,
                    indexBuffer,
                    textures);

    return submesh;
}


Mesh createMeshFromModelIOMesh(MDLMesh *modelIOMesh,
                               MDLVertexDescriptor *vertexDescriptor,
                               MTKTextureLoader* textureLoader,
                               MTL::Device* pDevice,
                               NS::Error** pError)
{

    // Have ModelIO create the tangents from mesh texture coordinates and normals
    [modelIOMesh addTangentBasisForTextureCoordinateAttributeNamed:MDLVertexAttributeTextureCoordinate
                                              normalAttributeNamed:MDLVertexAttributeNormal
                                             tangentAttributeNamed:MDLVertexAttributeTangent];

    // Have ModelIO create bitangents from mesh texture coordinates and the newly created tangents
    [modelIOMesh addTangentBasisForTextureCoordinateAttributeNamed:MDLVertexAttributeTextureCoordinate
                                             tangentAttributeNamed:MDLVertexAttributeTangent
                                           bitangentAttributeNamed:MDLVertexAttributeBitangent];

    // Apply the ModelIO vertex descriptor that the renderer created to match the Metal vertex descriptor.

    // Assigning a new vertex descriptor to a ModelIO mesh performs a re-layout of the vertex
    // vertex data.  In this case, the renderer created the ModelIO vertex descriptor so that the
    // layout of the vertices in the ModelIO mesh match the layout of vertices the Metal render
    // pipeline expects as input into its vertex shader

    // Note ModelIO must create tangents and bitangents (as done above) before this re-layout occurs
    // This is because Model IO's addTangentBasis methods only works with vertex data is all in
    // 32-bit floating-point. When the vertex descriptor is applied, changes those floats into
    // 16-bit floats or other types from which ModelIO cannot produce tangents.

    modelIOMesh.vertexDescriptor = vertexDescriptor;


    NSError* err = nil;
    
    std::vector<MeshBuffer> vertexBuffers;
    // Create the MetalKit mesh which will contain the Metal buffer(s) with the mesh's vertex data
    //   and submeshes with info to draw the mesh.
    MTKMesh* metalKitMesh = [[MTKMesh alloc] initWithMesh:modelIOMesh
                                                   device:(__bridge id<MTLDevice>)pDevice
                                                    error:&err];

    AAPL_ASSERT( !err, "Error loading MTKMesh" );
    if (pError && err)
    {
        *pError = (__bridge_retained NS::Error*)err;
    }
    
    for(NSUInteger argumentIndex = 0; argumentIndex < metalKitMesh.vertexBuffers.count; argumentIndex++)
    {
        MTKMeshBuffer * mtkMeshBuffer = metalKitMesh.vertexBuffers[argumentIndex];
        if((NSNull*)mtkMeshBuffer != [NSNull null])
        {
            MTL::Buffer* pBuffer = (__bridge_retained MTL::Buffer *)mtkMeshBuffer.buffer;

            vertexBuffers.emplace_back( MeshBuffer(pBuffer,
                                                   mtkMeshBuffer.offset,
                                                   mtkMeshBuffer.length,
                                                   argumentIndex) );
        }
    }

    std::vector<Submesh> submeshes;

    // Create a submesh object for each submesh and add it to the submesh's array.
    for(NSUInteger index = 0; index < metalKitMesh.submeshes.count; index++)
    {
        // Create an app specific submesh to hold the MetalKit submesh
        auto submesh = createSubmesh(modelIOMesh.submeshes[index],
                                     metalKitMesh.submeshes[index],
                                     pDevice,
                                     textureLoader);
        
        submeshes.push_back( submesh );
    }


    Mesh mesh(submeshes, vertexBuffers);

    return mesh;
}

static std::vector<Mesh> createMeshesFromModelIOObject(MDLObject* object,
                                                       MDLVertexDescriptor * vertexDescriptor,
                                                       MTKTextureLoader* textureLoader,
                                                       MTL::Device* pDevice,
                                                       NS::Error** pError)
{
    std::vector<Mesh> newMeshes;

    // If this ModelIO object is a mesh object (not a camera, light, or something else)...
    if ([object isKindOfClass:[MDLMesh class]])
    {
        //...create an app-specific Mesh object from it
        MDLMesh* modelIOMesh = (MDLMesh *)object;

        auto mesh = createMeshFromModelIOMesh(modelIOMesh,
                                               vertexDescriptor,
                                               textureLoader,
                                               pDevice,
                                               pError);

        newMeshes.push_back( mesh );
    }

    // Recursively traverse the ModelIO asset hierarchy to find ModelIO meshes that are children
    // of this ModelIO object and create app-specific Mesh objects from those ModelIO meshes
    for (MDLObject *child in object.children)
    {
        std::vector<Mesh> childMeshes;

        childMeshes = createMeshesFromModelIOObject(child, vertexDescriptor, textureLoader, pDevice, pError);

        newMeshes.insert(newMeshes.end(), childMeshes.begin(), childMeshes.end());
    }

    return newMeshes;
}

std::vector<Mesh> newMeshesFromBundlePath(const char* bundlePath,
                                          MTL::Device* pDevice,
                                          const MTL::VertexDescriptor& vertexDescriptor,
                                          NS::Error** pError)
{
    // Create a ModelIO vertexDescriptor so that the format/layout of the ModelIO mesh vertices
    //   cah be made to match Metal render pipeline's vertex descriptor layout
    MDLVertexDescriptor *modelIOVertexDescriptor =
    MTKModelIOVertexDescriptorFromMetal( (__bridge MTLVertexDescriptor *)(&vertexDescriptor) );

    // Indicate how each Metal vertex descriptor attribute maps to each ModelIO attribute
    modelIOVertexDescriptor.attributes[VertexAttributePosition].name  = MDLVertexAttributePosition;
    modelIOVertexDescriptor.attributes[VertexAttributeTexcoord].name  = MDLVertexAttributeTextureCoordinate;
    modelIOVertexDescriptor.attributes[VertexAttributeNormal].name    = MDLVertexAttributeNormal;
    modelIOVertexDescriptor.attributes[VertexAttributeTangent].name   = MDLVertexAttributeTangent;
    modelIOVertexDescriptor.attributes[VertexAttributeBitangent].name = MDLVertexAttributeBitangent;

    NSString *nsBunldePath = [[NSString alloc] initWithUTF8String:bundlePath];
    NSURL *modelFileURL = [[NSBundle mainBundle] URLForResource:nsBunldePath withExtension:nil];

    AAPL_ASSERT( modelFileURL, "Could not find model file in bundle: ", modelFileURL.absoluteString.UTF8String );

    // Create a MetalKit mesh buffer allocator so that ModelIO will load mesh data directly into
    // Metal buffers accessible by the GPU.
    MTKMeshBufferAllocator *bufferAllocator =
        [[MTKMeshBufferAllocator alloc] initWithDevice:(__bridge id<MTLDevice>)pDevice];

    // Use ModelIO to load the model file at the URL.  This returns a ModelIO asset object, which
    // contains a hierarchy of ModelIO objects composing a "scene" described by the model file.
    // This hierarchy may include lights, cameras, and, most importantly, mesh and submesh data
    // that we'll render with Metal.
    MDLAsset *asset = [[MDLAsset alloc] initWithURL:modelFileURL
                                   vertexDescriptor:nil
                                    bufferAllocator:bufferAllocator];

    AAPL_ASSERT( asset, "Failed to open model file with given URL:", modelFileURL.absoluteString.UTF8String );

    // Create a MetalKit texture loader to load material textures from files or the asset catalog
    //   into Metal textures.
    MTKTextureLoader* textureLoader = [[MTKTextureLoader alloc] initWithDevice:(__bridge id<MTLDevice>)pDevice];

    std::vector<Mesh> newMeshes;

    NS::Error* pInternalError = nullptr;

    // Traverse the ModelIO asset hierarchy to find ModelIO meshes and create app-specific
    // mesh objects from those ModelIO meshes.
    for(MDLObject* object in asset)
    {
        const std::vector<Mesh>& assetMeshes = createMeshesFromModelIOObject(object,
                                                                             modelIOVertexDescriptor,
                                                                             textureLoader,
                                                                             pDevice,
                                                                             &pInternalError);
        
        newMeshes.insert(newMeshes.end(), assetMeshes.begin(), assetMeshes.end());
    }

    AAPL_ASSERT_NULL_ERROR( pInternalError, "Error loading model:" );
    if(pInternalError && pError)
    {
        *pError = pInternalError;
    }

    return newMeshes;
}

static size_t alignSize(size_t inSize, size_t alignment)
{
    // Asset if align is not a power of 2
    assert(((alignment-1) & alignment) == 0);

    const NSUInteger alignmentMask = alignment - 1;

    return ((inSize + alignmentMask) & (~alignmentMask));
}

std::vector<MeshBuffer>
MeshBuffer::makeVertexBuffers(MTL::Device* pDevice,
                              const MTL::VertexDescriptor* pDescriptor,
                              NS::UInteger vertexCount,
                              NS::UInteger indexBufferSize)
{
    std::set<NS::UInteger> bufferIndicessUsed;

    for(int i = 0; i < 31; i++)
    {
        bufferIndicessUsed.insert(pDescriptor->attributes()->object(i)->bufferIndex());
    }

    std::vector<MeshBuffer> vertexBuffers;

    indexBufferSize = alignSize(indexBufferSize, 256);

    NS::UInteger bufferLength = indexBufferSize;
    for(auto bufferIndex : bufferIndicessUsed)
    {
        NS::UInteger offset = bufferLength;
        NS::UInteger sectionLength = alignSize(vertexCount * pDescriptor->layouts()->object(bufferIndex)->stride(), 256);

        bufferLength += sectionLength;

        vertexBuffers.emplace_back( MeshBuffer(nullptr, offset, sectionLength, bufferIndex) );
    }

    MTL::Buffer* pMetalBuffer = pDevice->newBuffer(bufferLength, MTL::ResourceStorageModeShared);

    for(auto&& vertexBuffer : vertexBuffers)
    {
        // safe to assume vertexBuffer.m_pBuffer is nullptr, no need to release it here
        vertexBuffer.m_pBuffer = pMetalBuffer->retain();
    }
    
    pMetalBuffer->release();

    return vertexBuffers;
}

static void packVertexData(void *output, MTL::VertexFormat format, vector_float4 value)
{
    switch( format )
    {
        case MTL::VertexFormatUChar4Normalized:
            ((uint8_t*)output)[3] = 0xFF * value.w;
        case MTL::VertexFormatUChar3Normalized:
            ((uint8_t*)output)[2] = 0xFF * value.z;
        case MTL::VertexFormatUChar2Normalized:
            ((uint8_t*)output)[1] = 0xFF * value.y;
            ((uint8_t*)output)[0] = 0xFF * value.x;
            break;
        case MTL::VertexFormatChar4Normalized:
            ((int8_t*)output)[3] = 0x7F * (2.0 * value.w -1.0);
        case MTL::VertexFormatChar3Normalized:
            ((int8_t*)output)[2] = 0x7F * (2.0 * value.z -1.0);
        case MTL::VertexFormatChar2Normalized:
            ((int8_t*)output)[1] = 0x7F * (2.0 * value.y -1.0);
            ((int8_t*)output)[0] = 0x7F * (2.0 * value.x -1.0);
            break;
        case MTL::VertexFormatUShort4Normalized:
            ((uint16_t*)output)[3] = 0xFFFF * (2.0 * value.w -1.0);
        case MTL::VertexFormatUShort3Normalized:
            ((uint16_t*)output)[2] = 0xFFFF * (2.0 * value.z -1.0);
        case MTL::VertexFormatUShort2Normalized:
            ((uint16_t*)output)[1] = 0xFFFF * (2.0 * value.y -1.0);
            ((uint16_t*)output)[0] = 0xFFFF * (2.0 * value.x -1.0);
            break;
        case MTL::VertexFormatShort4Normalized:
            ((int16_t*)output)[3] = 0x7FFF * (2.0 * value.w -1.0);
        case MTL::VertexFormatShort3Normalized:
            ((int16_t*)output)[2] = 0x7FFF * (2.0 * value.z -1.0);
        case MTL::VertexFormatShort2Normalized:
            ((int16_t*)output)[1] = 0x7FFF * (2.0 * value.y -1.0);
            ((int16_t*)output)[0] = 0x7FFF * (2.0 * value.x -1.0);
            break;
        case MTL::VertexFormatHalf4:
            ((__fp16 *)output)[3] = value.w;
        case MTL::VertexFormatHalf3:
            ((__fp16 *)output)[2] = value.z;
        case MTL::VertexFormatHalf2:
            ((__fp16 *)output)[1] = value.y;
            ((__fp16 *)output)[0] = value.x;
            break;
        case MTL::VertexFormatFloat4:
            ((float*)output)[3] = value.w;
        case MTL::VertexFormatFloat3:
            ((float*)output)[2] = value.z;
        case MTL::VertexFormatFloat2:
            ((float*)output)[1] = value.y;
        case MTL::VertexFormatFloat:
            ((float*)output)[0] = value.x;
            break;
        default:
            break;
    }
}

Mesh makeSphereMesh(MTL::Device* pDevice,
                    const MTL::VertexDescriptor& vertexDescriptor,
                    int radialSegments, int verticalSegments, float radius)
{
    const NS::UInteger vertexCount = 2 + (radialSegments) * (verticalSegments-1);
    const NS::UInteger indexCount  = 6 * radialSegments * (verticalSegments-1);;

    const NS::UInteger indexBufferSize = indexCount*sizeof(ushort);

    assert(vertexCount < UINT16_MAX);

    std::vector<MeshBuffer> vertexBuffers;

    vertexBuffers = MeshBuffer::makeVertexBuffers(pDevice,
                                                  &vertexDescriptor,
                                                  vertexCount,
                                                  indexBufferSize);

    MTL::Buffer* pMetalBuffer = vertexBuffers[0].buffer();

    // Create index buffer from the Metal buffer shared with the vertices and reserve space at the
    // beginning for indices.
    MeshBuffer indexBuffer(pMetalBuffer, 0, indexBufferSize);

    uint8_t *bufferContents =  (uint8_t *)pMetalBuffer->contents();

    // Fill IndexBuffer
    {
        ushort *indices = (ushort *)bufferContents;

        NS::UInteger currentIndex = 0;

        // Indices for top of sphere
        for (ushort phi = 0; phi < radialSegments; phi++)
        {
            if(phi < radialSegments - 1)
            {
                indices[currentIndex++] = 0;
                indices[currentIndex++] = 2 + phi;
                indices[currentIndex++] = 1 + phi;
            }
            else
            {
                indices[currentIndex++] = 0;
                indices[currentIndex++] = 1;
                indices[currentIndex++] = 1 + phi;
            }
        }

        // Indices middle of sphere
        for(ushort theta = 0; theta < verticalSegments-2; theta++)
        {
            ushort topRight;
            ushort topLeft;
            ushort bottomRight;
            ushort bottomLeft;

            for(ushort phi = 0; phi < radialSegments; phi++)
            {
                if(phi < radialSegments - 1)
                {
                    topRight    = 1 + theta * (radialSegments) + phi;
                    topLeft     = 1 + theta * (radialSegments) + (phi + 1);
                    bottomRight = 1 + (theta + 1) * (radialSegments) + phi;
                    bottomLeft  = 1 + (theta + 1) * (radialSegments) + (phi + 1);
                }
                else
                {
                    topRight    = 1 + theta * (radialSegments) + phi;
                    topLeft     = 1 + theta * (radialSegments);
                    bottomRight = 1 + (theta + 1) * (radialSegments) + phi;
                    bottomLeft  = 1 + (theta + 1) * (radialSegments);
                }

                indices[currentIndex++] = topRight;
                indices[currentIndex++] = bottomLeft;
                indices[currentIndex++] = bottomRight;

                indices[currentIndex++] = topRight;
                indices[currentIndex++] = topLeft;
                indices[currentIndex++] = bottomLeft;
            }
        }

        // indices for bottom of sphere
        ushort lastIndex = radialSegments * (verticalSegments-1) + 1;
        for(ushort phi = 0; phi < radialSegments; phi++)
        {
            if(phi < radialSegments - 1)
            {
                indices[currentIndex++] = lastIndex;
                indices[currentIndex++] = lastIndex - radialSegments + phi;
                indices[currentIndex++] = lastIndex - radialSegments + phi + 1;
            }
            else
            {
                indices[currentIndex++] = lastIndex;
                indices[currentIndex++] = lastIndex - radialSegments + phi;
                indices[currentIndex++] = lastIndex - radialSegments ;
            }
        }
    }

    // Fill positions and normals
    {
        MTL::VertexFormat positionFormat      = vertexDescriptor.attributes()->object(VertexAttributePosition)->format();
        NS::UInteger positionBufferIndex  = vertexDescriptor.attributes()->object(VertexAttributePosition)->bufferIndex();
        NS::UInteger positionVertexOffset = vertexDescriptor.attributes()->object(VertexAttributePosition)->offset();
        NS::UInteger positionBufferOffset = vertexBuffers[positionBufferIndex].offset();
        NS::UInteger positionStride       = vertexDescriptor.layouts()->object(positionBufferIndex)->stride();

        MTL::VertexFormat normalFormat       = vertexDescriptor.attributes()->object(VertexAttributeNormal)->format();
        NS::UInteger normalBufferIndex  = vertexDescriptor.attributes()->object(VertexAttributeNormal)->bufferIndex();
        NS::UInteger normalVertexOffset = vertexDescriptor.attributes()->object(VertexAttributeNormal)->offset();
        NS::UInteger normalBufferOffset = vertexBuffers[normalBufferIndex].offset();
        NS::UInteger normalStride       = vertexDescriptor.layouts()->object(normalBufferIndex)->stride();

        const double radialDelta   = 2 * (M_PI / radialSegments);
        const double verticalDelta = (M_PI / verticalSegments);

        uint8_t *positionData = bufferContents + positionBufferOffset + positionVertexOffset;
        uint8_t *normalData   = bufferContents + normalBufferOffset + normalVertexOffset;

        vector_float4 vertexPosition = {0, radius, 0, 1};
        vector_float4 vertexNormal = {0, 1, 0, 1};;

        packVertexData(positionData, positionFormat, vertexPosition);
        packVertexData(normalData, normalFormat, vertexNormal);

        positionData += positionStride;
        normalData   += normalStride;

        for (ushort verticalSegment = 1; verticalSegment < verticalSegments; verticalSegment++)
        {
            const double verticalPosition = verticalSegment * verticalDelta;

            float y = cos(verticalPosition);

            for (ushort radialSegment = 0; radialSegment < radialSegments; radialSegment++)
            {
                const double radialPosition = radialSegment * radialDelta;

                vector_float4 unscaledPosition;

                unscaledPosition.x = sin(verticalPosition) * cos(radialPosition);
                unscaledPosition.y = y;
                unscaledPosition.z = sin(verticalPosition) * sin(radialPosition);
                unscaledPosition.w = 1.0;

                vertexPosition = radius * unscaledPosition;
                vertexNormal   = unscaledPosition;

                packVertexData(positionData, positionFormat, vertexPosition);
                packVertexData(normalData, normalFormat, vertexNormal);

                positionData += positionStride;
                normalData   += normalStride;

            }
        }

        vertexPosition = {0, -radius, 0, 1};
        vertexNormal = {0, -1, 0, 1};;

        packVertexData(positionData, positionFormat, vertexPosition);
        packVertexData(normalData, normalFormat, vertexNormal);

    }

    Submesh submesh(MTL::PrimitiveTypeTriangle,
                    MTL::IndexTypeUInt16,
                    indexCount,
                    indexBuffer);

    return Mesh(submesh, vertexBuffers);
}


Mesh makeIcosahedronMesh(MTL::Device* pDevice,
                         const MTL::VertexDescriptor& vertexDescriptor,
                         float radius)
{
    const float Z = radius;
    const float X = (Z / (1.0 + sqrtf(5.0))) * 2;
    const vector_float4 positions[] =
    {
        {  -X, 0.0,   Z },
        {   X, 0.0,   Z },
        {  -X, 0.0,  -Z },
        {   X, 0.0,  -Z },
        { 0.0,   Z,   X },
        { 0.0,   Z,  -X },
        { 0.0,  -Z,   X },
        { 0.0,  -Z,  -X },
        {   Z,   X, 0.0 },
        {  -Z,   X, 0.0 },
        {   Z,  -X, 0.0 },
        {  -Z,  -X, 0.0 }
    };

    const uint16_t vertexCount = sizeof(positions) / sizeof(vector_float3);

    const uint16_t indices[][3] =
    {
        {  0,  1,  4 },
        {  0,  4,  9 },
        {  9,  4,  5 },
        {  4,  8,  5 },
        {  4,  1,  8 },
        {  8,  1, 10 },
        {  8, 10,  3 },
        {  5,  8,  3 },
        {  5,  3,  2 },
        {  2,  3,  7 },
        {  7,  3, 10 },
        {  7, 10,  6 },
        {  7,  6, 11 },
        { 11,  6,  0 },
        {  0,  6,  1 },
        {  6, 10,  1 },
        {  9, 11,  0 },
        {  9,  2, 11 },
        {  9,  5,  2 },
        {  7, 11,  2 }
    };

    NS::UInteger indexCount = sizeof(indices) / sizeof(uint16_t);
    NS::UInteger indexBufferSize = sizeof(indices);

    std::vector<MeshBuffer> vertexBuffers = MeshBuffer::makeVertexBuffers(pDevice,
                                                                          &vertexDescriptor,
                                                                          vertexCount,
                                                                          indexBufferSize);

    MTL::Buffer* pBuffer = vertexBuffers[0].buffer();

    MeshBuffer indexBuffer(pBuffer, 0, indexBufferSize);

    uint8_t * bufferContents = (uint8_t*)pBuffer->contents();

    memcpy(bufferContents, indices, indexBufferSize);

    {
        MTL::VertexFormat positionFormat      = vertexDescriptor.attributes()->object(VertexAttributePosition)->format();
        NS::UInteger positionBufferIndex  = vertexDescriptor.attributes()->object(VertexAttributePosition)->bufferIndex();
        NS::UInteger positionVertexOffset = vertexDescriptor.attributes()->object(VertexAttributePosition)->offset();
        NS::UInteger positionBufferOffset = vertexBuffers[positionBufferIndex].offset();
        NS::UInteger positionStride       = vertexDescriptor.layouts()->object(positionBufferIndex)->stride();


        uint8_t *positionData = bufferContents + positionBufferOffset + positionVertexOffset;

        for(uint16_t vertexIndex = 0; vertexIndex < vertexCount; vertexIndex++)
        {
            packVertexData(positionData, positionFormat, positions[vertexIndex]);
            positionData += positionStride;
        }
    }

    Submesh submesh(MTL::PrimitiveTypeTriangle,
                    MTL::IndexTypeUInt16,
                    indexCount,
                    indexBuffer);

    return Mesh(submesh, vertexBuffers);
}

MTL::Texture* newTextureFromCatalog( MTL::Device* pDevice, const char* name, MTL::StorageMode storageMode, MTL::TextureUsage usage )
{
    NSDictionary<MTKTextureLoaderOption, id>* options = @{
            MTKTextureLoaderOptionTextureStorageMode : @( (MTLStorageMode)storageMode ),
            MTKTextureLoaderOptionTextureUsage : @( (MTLTextureUsage)usage )
    };
        
    MTKTextureLoader* textureLoader = [[MTKTextureLoader alloc] initWithDevice:(__bridge id<MTLDevice>)pDevice];

    NSError* __autoreleasing err = nil;
    id< MTLTexture > texture = [textureLoader newTextureWithName:[NSString stringWithUTF8String:name]
                                                     scaleFactor:1
                                                          bundle:nil
                                                         options:options
                                                           error:&err];

    AAPL_ASSERT( !err, "Error loading texture:", name );
    
    return (__bridge_retained MTL::Texture*)texture;
}
