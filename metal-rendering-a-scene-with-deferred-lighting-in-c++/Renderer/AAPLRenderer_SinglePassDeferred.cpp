/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the renderer class which performs Metal setup and per frame rendering for a
 single pass deferred renderer used for iOS & tvOS devices in addition to macOS devices with
 Apple Silicon.
*/

#include "AAPLRenderer_SinglePassDeferred.h"

// Include header shared between C code here, which executes Metal API commands, and .metal files
#include "Shaders/AAPLShaderTypes.h"

#include "AAPLUtilities.h"

Renderer_SinglePassDeferred::Renderer_SinglePassDeferred( MTL::Device* pDevice )
: Renderer( pDevice )
{
    m_singlePassDeferred = true;

    m_GBufferStorageMode = MTL::StorageModeMemoryless;

    loadMetalInternal();
    loadScene();
}

Renderer_SinglePassDeferred::~Renderer_SinglePassDeferred()
{
    m_pLightPipelineState->release();
    m_pViewRenderPassDescriptor->release();
}

void Renderer_SinglePassDeferred::loadMetalInternal()
{
    Renderer::loadMetal();
    NS::Error* pError = nullptr;

    #pragma mark Point light render pipeline setup
    {
        MTL::RenderPipelineDescriptor* pRenderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();

        pRenderPipelineDescriptor->setLabel( AAPLSTR( "Light" ) );
        pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetLighting)->setPixelFormat(colorTargetPixelFormat());
        pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setPixelFormat(m_albedo_specular_GBufferFormat);
        pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetNormal)->setPixelFormat(m_normal_shadow_GBufferFormat);
        pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetDepth)->setPixelFormat(m_depth_GBufferFormat);
        pRenderPipelineDescriptor->setDepthAttachmentPixelFormat(depthStencilTargetPixelFormat());
        pRenderPipelineDescriptor->setStencilAttachmentPixelFormat(depthStencilTargetPixelFormat());

        MTL::Library* pShaderLibrary = m_pDevice->newDefaultLibrary();

        AAPL_ASSERT( pShaderLibrary, "Failed to create default shader library" );

        MTL::Function* pLightVertexFunction = pShaderLibrary->newFunction( AAPLSTR( "deferred_point_lighting_vertex" ) );
        MTL::Function* pLightFragmentFunction = pShaderLibrary->newFunction( AAPLSTR( "deferred_point_lighting_fragment_single_pass" ) );

        AAPL_ASSERT( pLightVertexFunction, "Failed to load deferred_point_lighting_vertex" );
        AAPL_ASSERT( pLightFragmentFunction, "Failed to load deferred_point_lighting_fragment_single_pass" );

        pRenderPipelineDescriptor->setVertexFunction( pLightVertexFunction );
        pRenderPipelineDescriptor->setFragmentFunction( pLightFragmentFunction );

        m_pLightPipelineState = m_pDevice->newRenderPipelineState( pRenderPipelineDescriptor, &pError );

        AAPL_ASSERT_NULL_ERROR( pError, "Failed to create lighting render pipeline state" );
        
        pLightVertexFunction->release();
        pLightFragmentFunction->release();
        pRenderPipelineDescriptor->release();
        pShaderLibrary->release();
    }

    #pragma mark GBuffer + View render pass descriptor setup
    m_pViewRenderPassDescriptor = MTL::RenderPassDescriptor::alloc()->init();
    m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setLoadAction(MTL::LoadActionDontCare);
    m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setStoreAction(MTL::StoreActionDontCare);
    m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetNormal)->setLoadAction(MTL::LoadActionDontCare);
    m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetNormal)->setStoreAction(MTL::StoreActionDontCare);
    m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetDepth)->setLoadAction(MTL::LoadActionDontCare);
    m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetDepth)->setStoreAction(MTL::StoreActionDontCare);
    m_pViewRenderPassDescriptor->depthAttachment()->setLoadAction( MTL::LoadActionClear );
    m_pViewRenderPassDescriptor->depthAttachment()->setStoreAction( MTL::StoreActionDontCare) ;
    m_pViewRenderPassDescriptor->stencilAttachment()->setLoadAction( MTL::LoadActionClear );
    m_pViewRenderPassDescriptor->stencilAttachment()->setStoreAction( MTL::StoreActionDontCare );
    m_pViewRenderPassDescriptor->depthAttachment()->setClearDepth( 1.0 );
    m_pViewRenderPassDescriptor->stencilAttachment()->setClearStencil( 0 );

}

/// Respond to view size change
void Renderer_SinglePassDeferred::drawableSizeWillChange(const MTL::Size& size, MTL::StorageMode GBufferStorageMode)
{
    m_drawableSize = size;
    
    // The renderer base class allocates all GBuffers except lighting GBuffer, because with the
    // single-pass deferred renderer, the lighting buffer is the same as the drawable.
    Renderer::drawableSizeWillChange(size, m_GBufferStorageMode);

    // Re-set GBuffer textures in the GBuffer render pass descriptor after they have been
    // reallocated by a resize
    m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setTexture(m_albedo_specular_GBuffer);
    m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetNormal)->setTexture(m_normal_shadow_GBuffer);
    m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetDepth)->setTexture(m_depth_GBuffer);
}

/// Frame drawing routine
void Renderer_SinglePassDeferred::drawInView( bool isPaused, MTL::Drawable* pCurrentDrawable, MTL::Texture* pDepthStencilTexture )
{
    MTL::CommandBuffer* pCommandBuffer = beginFrame( isPaused );
    pCommandBuffer->setLabel( AAPLSTR( "Shadow commands" ) );

    drawShadow( pCommandBuffer );
    pCommandBuffer->commit();

    pCommandBuffer = beginDrawableCommands();
    pCommandBuffer->setLabel( AAPLSTR( "GBuffer & Lighting Commands" ) );

    MTL::Texture* pDrawableTexture = currentDrawableTexture( pCurrentDrawable );
    if ( pDrawableTexture )
    {
        m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetLighting)->setTexture( pDrawableTexture );
        m_pViewRenderPassDescriptor->depthAttachment()->setTexture( pDepthStencilTexture );
        m_pViewRenderPassDescriptor->stencilAttachment()->setTexture( pDepthStencilTexture );

        MTL::RenderCommandEncoder* pRenderEncoder = pCommandBuffer->renderCommandEncoder(m_pViewRenderPassDescriptor);
        pRenderEncoder->setLabel( AAPLSTR( "Combined GBuffer & Lighting Pass" ) );

        Renderer::drawGBuffer( pRenderEncoder );

        drawDirectionalLight( pRenderEncoder );

        Renderer::drawPointLightMask( pRenderEncoder );

        drawPointLights( pRenderEncoder );

        Renderer::drawSky( pRenderEncoder );

        Renderer::drawFairies( pRenderEncoder );

        pRenderEncoder->endEncoding();
    }

    endFrame( pCommandBuffer, pCurrentDrawable );
}

void Renderer_SinglePassDeferred::drawDirectionalLight(MTL::RenderCommandEncoder* pRenderEncoder)
{
    pRenderEncoder->pushDebugGroup( AAPLSTR( "Draw Directional Light" ) );

    Renderer::drawDirectionalLightCommon( pRenderEncoder );

    pRenderEncoder->popDebugGroup();
}

void Renderer_SinglePassDeferred::drawPointLights(MTL::RenderCommandEncoder* pRenderEncoder)
{
    pRenderEncoder->pushDebugGroup( AAPLSTR( "Draw Point Lights" ) );

    pRenderEncoder->setRenderPipelineState( m_pLightPipelineState );

    // Call the common base class method after setting the state in the renderEncoder specific to the
    // single-pass deferred renderer
    Renderer::drawPointLightsCommon( pRenderEncoder );

    pRenderEncoder->popDebugGroup();
}

#if SUPPORT_BUFFER_EXAMINATION

/// Set up render targets for display when buffer examination mode enabled. Set up target for
/// optimal rendering when buffer examination mode disabled.
void Renderer_SinglePassDeferred::validateBufferExaminationMode()
{
    // When in buffer examination mode, the renderer must allocate the GBuffers with
    // StorageModePrivate since the buffer examination manager needs the GBuffers written to main
    // memory to render them on screen later.
    // However, when a buffer examination mode is not enabled, the renderer only needs the GBuffers
    // in the GPU tile memory, so it can use StorageModeMemoryless to conserve memory.

    if( m_bufferExaminationManager->mode())
    {
        // Clear the background of the GBuffer when examining buffers. When rendering normally
        // clearing is wasteful, but when examining the buffers, the backgrounds appear corrupt
        // making unclear what's actually rendered to the buffers
        m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setLoadAction( MTL::LoadActionClear );
        m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetNormal)->setLoadAction( MTL::LoadActionClear );
        m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetDepth)->setLoadAction( MTL::LoadActionClear );

        // Store results of all buffers to examine them.  This is wasteful when rendering
        // normally, but necessary to present them on screen.
        m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setStoreAction( MTL::StoreActionStore );
        m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetNormal)->setStoreAction( MTL::StoreActionStore );
        m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetDepth)->setStoreAction( MTL::StoreActionStore );
        m_pViewRenderPassDescriptor->depthAttachment()->setStoreAction( MTL::StoreActionStore );
        m_pViewRenderPassDescriptor->stencilAttachment()->setStoreAction( MTL::StoreActionStore );

        m_GBufferStorageMode = MTL::StorageModePrivate;
    }
    else
    {
        // When exiting buffer examination mode, return to efficient state settings
        m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setLoadAction( MTL::LoadActionDontCare );
        m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetNormal)->setLoadAction( MTL::LoadActionDontCare );
        m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetDepth)->setLoadAction( MTL::LoadActionDontCare );
        m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setStoreAction( MTL::StoreActionDontCare );
        m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetNormal)->setStoreAction( MTL::StoreActionDontCare );
        m_pViewRenderPassDescriptor->colorAttachments()->object(RenderTargetDepth)->setStoreAction( MTL::StoreActionDontCare );
        m_pViewRenderPassDescriptor->depthAttachment()->setStoreAction( MTL::StoreActionDontCare );
        m_pViewRenderPassDescriptor->stencilAttachment()->setStoreAction( MTL::StoreActionDontCare );

        m_GBufferStorageMode = MTL::StorageModeMemoryless;
    }

    // Force reallocation of GBuffers.
    drawableSizeWillChange( m_drawableSize, m_GBufferStorageMode );
}

#endif // SUPPORT_BUFFER_EXAMINATION
