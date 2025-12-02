/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for renderer class that performs Metal setup and per-frame rendering.
*/
#ifndef AAPLRenderer_h
#define AAPLRenderer_h
#include "AAPLConfig.h"
#include "AAPLBufferExaminationManager.h"

#include "AAPLMesh.h"

#include <Metal/Metal.hpp>

// The maximum number of command buffers in flight
constexpr uint8_t MaxFramesInFlight = 3;

// Number of "fairy" lights in scene
static const uint32_t NumLights = 256;

static const float NearPlane = 1;
static const float FarPlane = 150;

class Renderer
{
public:

    explicit Renderer( MTL::Device* pDevice );

    virtual ~Renderer();
    
    MTL::Device* device() const;

    const Mesh& icosahedronMesh() const;

    MTL::PixelFormat colorTargetPixelFormat() const;

    MTL::PixelFormat depthStencilTargetPixelFormat() const;

    const MTL::Buffer* quadVertexBuffer() const;

    int8_t frameDataBufferIndex() const;

    MTL::Buffer* frameDataBuffer(int8_t frameDataBufferIndex) const;

    MTL::Buffer* lightPositions(int8_t frameDataBufferIndex) const;

    MTL::Buffer* lightsData() const;

    MTL::DepthStencilState* pointLightDepthStencilState() const;

    MTL::Texture* albedo_specular_GBuffer() const;

    MTL::Texture* normal_shadow_GBuffer() const;

    MTL::Texture* depth_GBuffer() const;

    MTL::Texture* shadowMap() const;
    virtual void drawableSizeWillChange(const MTL::Size& size, MTL::StorageMode GBufferStorageMode) = 0;

    virtual void drawInView( bool isPaused, MTL::Drawable* pCurrentDrawable, MTL::Texture* pDepthStencilTexture ) = 0;

#if SUPPORT_BUFFER_EXAMINATION

    virtual void validateBufferExaminationMode() = 0;

    void bufferExaminationManager( BufferExaminationManager * bufferExaminationManager );

#endif

protected:

    virtual void loadMetal();

    void loadScene();

    MTL::CommandBuffer* beginFrame( bool isPaused );

    MTL::CommandBuffer* beginDrawableCommands();

    void endFrame(MTL::CommandBuffer* pCommandBuffer, MTL::Drawable* pCurrentDrawable);

    void drawShadow( MTL::CommandBuffer* pCommandBuffer );

    void drawGBuffer( MTL::RenderCommandEncoder* pRenderEncoder );

    void drawDirectionalLightCommon( MTL::RenderCommandEncoder* pRenderEncoder );

    void drawPointLightMask( MTL::RenderCommandEncoder* pRenderEncoder );

    void drawPointLightsCommon( MTL::RenderCommandEncoder* pRenderEncoder );

    void drawFairies( MTL::RenderCommandEncoder* pRenderEncoder );

    void drawSky( MTL::RenderCommandEncoder* pRenderEncoder );

    MTL::Texture* currentDrawableTexture( MTL::Drawable* pCurrentDrawable );

    MTL::Device* m_pDevice;

    int8_t m_frameDataBufferIndex;

    // GBuffer properties

    MTL::PixelFormat m_albedo_specular_GBufferFormat;

    MTL::PixelFormat m_normal_shadow_GBufferFormat;

    MTL::PixelFormat m_depth_GBufferFormat;

    MTL::Texture* m_albedo_specular_GBuffer;

    MTL::Texture* m_normal_shadow_GBuffer;

    MTL::Texture* m_depth_GBuffer;

    // This is used to build render pipelines that perform common operations for both the iOS and macOS
    // renderers. The only difference between the iOS and macOS versions of these pipelines is that
    // the iOS renderer needs the GBuffers attached as render targets while the macOS renderer needs
    // the GBuffers set as textures to sample/read from. This is YES for the iOS renderer and NO
    // for the macOS renderer. This enables more sharing of the code to create these pipelines
    // in the implementation of the Renderer base class that is common to both renderers.
    bool m_singlePassDeferred;

    MTL::DepthStencilState * m_pDontWriteDepthStencilState;

private:

    void updateLights(const simd::float4x4 & modelViewMatrix);

    void updateWorldState( bool isPaused );

    void drawMeshes( MTL::RenderCommandEncoder* pRenderEncoder );

    dispatch_semaphore_t m_inFlightSemaphore;

//    MTL::CommandBufferHandler *m_completedHandler;

    // Vertex descriptor for models loaded with MetalKit
    MTL::VertexDescriptor* m_pDefaultVertexDescriptor;

    MTL::CommandQueue* m_pCommandQueue;

    // Pipeline states
    MTL::RenderPipelineState* m_pGBufferPipelineState;
    MTL::RenderPipelineState* m_pFairyPipelineState;
    MTL::RenderPipelineState* m_pSkyboxPipelineState;
    MTL::RenderPipelineState* m_pShadowGenPipelineState;
    MTL::RenderPipelineState* m_pDirectionalLightPipelineState;

    // Depth stencil states
    MTL::DepthStencilState* m_pDirectionLightDepthStencilState;
    MTL::DepthStencilState* m_pGBufferDepthStencilState;
    MTL::DepthStencilState* m_pShadowDepthStencilState;
    MTL::DepthStencilState* m_pPointLightDepthStencilState;

#if LIGHT_STENCIL_CULLING
    MTL::RenderPipelineState* m_pLightMaskPipelineState;
    MTL::DepthStencilState* m_pLightMaskDepthStencilState;
#endif

    MTL::RenderPassDescriptor* m_pShadowRenderPassDescriptor;

    // Depth render target for shadow map
    MTL::Texture* m_pShadowMap;

    // Texture to create smooth round particles
    MTL::Texture* m_pFairyMap;

    // Texture for skybox
    MTL::Texture* m_pSkyMap;

    // Buffers used to store dynamically changing per-frame data
    MTL::Buffer* m_frameDataBuffers[MaxFramesInFlight];

    // Buffers used to story dynamically changing light positions
    MTL::Buffer* m_lightPositions[MaxFramesInFlight];

    // Buffer for constant light data
    MTL::Buffer* m_pLightsData;

    // Mesh buffer for simple Quad
    MTL::Buffer* m_pQuadVertexBuffer;

    // Mesh buffer for fairies
    MTL::Buffer* m_pFairy;

    // Array of meshes loaded from the model file
    std::vector<Mesh> m_meshes;

    // Mesh for sphere used to render the skybox
    Mesh m_skyMesh;

    // Projection matrix calculated as a function of view size
    simd::float4x4 m_projection_matrix;

    // Projection matrix used to render the shadow map
    simd::float4x4 m_shadowProjectionMatrix;

    // Current frame number rendering
    uint64_t m_frameNumber;

    // Vertex descriptor for models loaded with MetalKit
    MTL::VertexDescriptor* m_pSkyVertexDescriptor;

    // Light positions before transformation to positions in current frame
    simd::float4 *m_originalLightPositions;
    // Mesh for an icosahedron used for rendering point lights
    Mesh m_icosahedronMesh;

    void populateLights();

#if SUPPORT_BUFFER_EXAMINATION

protected:

    BufferExaminationManager* m_bufferExaminationManager;

#endif // END SUPPORT_BUFFER_EXAMINATION

};


inline MTL::Device* Renderer::device() const
{
    return m_pDevice;
}

inline const Mesh& Renderer::icosahedronMesh() const
{
    return m_icosahedronMesh;
}

inline MTL::PixelFormat Renderer::colorTargetPixelFormat() const
{
    return MTL::PixelFormat::PixelFormatBGRA8Unorm_sRGB;
}

inline MTL::PixelFormat Renderer::depthStencilTargetPixelFormat() const
{
    return MTL::PixelFormat::PixelFormatDepth32Float_Stencil8;
}

inline const MTL::Buffer* Renderer::quadVertexBuffer() const
{
    return m_pQuadVertexBuffer;
}

inline int8_t Renderer::frameDataBufferIndex() const
{
    return m_frameDataBufferIndex;
}

inline MTL::Buffer* Renderer::frameDataBuffer(int8_t frameDataBufferIndex) const
{
    return m_frameDataBuffers[frameDataBufferIndex];
}

inline MTL::Buffer* Renderer::lightPositions(int8_t frameDataBufferIndex) const
{
    return m_lightPositions[frameDataBufferIndex];
}

inline MTL::Buffer* Renderer::lightsData() const
{
    return m_pLightsData;
}

inline MTL::DepthStencilState* Renderer::pointLightDepthStencilState() const
{
    return m_pPointLightDepthStencilState;
}

inline MTL::Texture* Renderer::albedo_specular_GBuffer() const
{
    return m_albedo_specular_GBuffer;
}

inline MTL::Texture* Renderer::normal_shadow_GBuffer() const
{
    return m_normal_shadow_GBuffer;
}

inline MTL::Texture* Renderer::depth_GBuffer() const
{
    return m_depth_GBuffer;
}

inline MTL::Texture* Renderer::shadowMap() const
{
    return m_pShadowMap;
}

#if SUPPORT_BUFFER_EXAMINATION

inline void Renderer::bufferExaminationManager( BufferExaminationManager * bufferExaminationManager )
{
    m_bufferExaminationManager = bufferExaminationManager;
}

#endif

#endif // AAPLRenderer_h
