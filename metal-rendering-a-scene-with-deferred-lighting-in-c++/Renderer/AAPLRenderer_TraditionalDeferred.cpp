/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the renderer class that performs Metal setup and per-frame rendering for a
 traditional deferred renderer used for macOS devices without Apple silicon and the
 iOS & tvOS simulators.
*/

#include "AAPLRenderer_TraditionalDeferred.h"

// Include header shared between C code here, which executes Metal API commands, and .metal files.
#include "AAPLShaderTypes.h"

#include "AAPLUtilities.h"

Renderer_TraditionalDeferred::Renderer_TraditionalDeferred(MTL::Device* pDevice)
: Renderer( pDevice )
{
    m_singlePassDeferred = false;
    loadMetalInternal();
    loadScene();
}

Renderer_TraditionalDeferred::~Renderer_TraditionalDeferred()
{
    m_pLightPipelineState->release();
    m_pGBufferRenderPassDescriptor->release();
    m_pFinalRenderPassDescriptor->release();
}

/// Create traditional deferred renderer specific Metal state objects
void Renderer_TraditionalDeferred::loadMetalInternal()
{
    Renderer::loadMetal();

    NS::Error* pError = nullptr;


    #pragma mark Point light render pipeline setup
    {
        MTL::RenderPipelineDescriptor* pRenderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();

        pRenderPipelineDescriptor->setLabel( AAPLSTR( "Light" ) );
        pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetLighting)->setPixelFormat( colorTargetPixelFormat() );

        // Enable additive blending
        pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetLighting)->setBlendingEnabled( true );
        pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetLighting)->setRgbBlendOperation( MTL::BlendOperationAdd );
        pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetLighting)->setAlphaBlendOperation( MTL::BlendOperationAdd );
        pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetLighting)->setDestinationRGBBlendFactor( MTL::BlendFactorOne );
        pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetLighting)->setDestinationAlphaBlendFactor( MTL::BlendFactorOne );
        pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetLighting)->setSourceRGBBlendFactor( MTL::BlendFactorOne );
        pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetLighting)->setSourceAlphaBlendFactor( MTL::BlendFactorOne );

        pRenderPipelineDescriptor->setDepthAttachmentPixelFormat( depthStencilTargetPixelFormat() );
        pRenderPipelineDescriptor->setStencilAttachmentPixelFormat( depthStencilTargetPixelFormat() );

        MTL::Library* pShaderLibrary = m_pDevice->newDefaultLibrary();

        AAPL_ASSERT( pShaderLibrary, "Failed to create default shader library" );

        MTL::Function* pLightVertexFunction = pShaderLibrary->newFunction( AAPLSTR( "deferred_point_lighting_vertex" ) );
        MTL::Function* pLightFragmentFunction = pShaderLibrary->newFunction( AAPLSTR( "deferred_point_lighting_fragment_traditional" ) );

        AAPL_ASSERT( pLightVertexFunction, "Failed to load deferred_point_lighting_vertex" );
        AAPL_ASSERT( pLightFragmentFunction, "Failed to load deferred_point_lighting_fragment_traditional" );

        pRenderPipelineDescriptor->setVertexFunction( pLightVertexFunction );
        pRenderPipelineDescriptor->setFragmentFunction( pLightFragmentFunction );

        m_pLightPipelineState = m_pDevice->newRenderPipelineState( pRenderPipelineDescriptor, &pError );

        AAPL_ASSERT_NULL_ERROR( pError, "Failed to create lighting render pipeline state" );
        
        pLightVertexFunction->release();
        pLightFragmentFunction->release();
        pRenderPipelineDescriptor->release();
        pShaderLibrary->release();
    }

    #pragma mark GBuffer render pass descriptor setup
    // Create a render pass descriptor to create an encoder for rendering to the GBuffers.
    // The encoder stores rendered data of each attachment when encoding ends.
    m_pGBufferRenderPassDescriptor = MTL::RenderPassDescriptor::alloc()->init();
    
    m_pGBufferRenderPassDescriptor->colorAttachments()->object(RenderTargetLighting)->setLoadAction( MTL::LoadActionDontCare );
    m_pGBufferRenderPassDescriptor->colorAttachments()->object(RenderTargetLighting)->setStoreAction( MTL::StoreActionDontCare );
    m_pGBufferRenderPassDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setLoadAction( MTL::LoadActionDontCare );
    m_pGBufferRenderPassDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setStoreAction( MTL::StoreActionStore );
    m_pGBufferRenderPassDescriptor->colorAttachments()->object(RenderTargetNormal)->setLoadAction( MTL::LoadActionDontCare );
    m_pGBufferRenderPassDescriptor->colorAttachments()->object(RenderTargetNormal)->setStoreAction( MTL::StoreActionStore );
    m_pGBufferRenderPassDescriptor->colorAttachments()->object(RenderTargetDepth)->setLoadAction( MTL::LoadActionDontCare );
    m_pGBufferRenderPassDescriptor->colorAttachments()->object(RenderTargetDepth)->setStoreAction( MTL::StoreActionStore );
    m_pGBufferRenderPassDescriptor->depthAttachment()->setClearDepth( 1.0 );
    m_pGBufferRenderPassDescriptor->depthAttachment()->setLoadAction( MTL::LoadActionClear );
    m_pGBufferRenderPassDescriptor->depthAttachment()->setStoreAction( MTL::StoreActionStore );

    m_pGBufferRenderPassDescriptor->stencilAttachment()->setClearStencil( 0 );
    m_pGBufferRenderPassDescriptor->stencilAttachment()->setLoadAction( MTL::LoadActionClear );
    m_pGBufferRenderPassDescriptor->stencilAttachment()->setStoreAction( MTL::StoreActionStore );

    // Create a render pass descriptor for the lighting and composition pass

    // Whatever rendered in the final pass needs to be stored so it can be displayed
    m_pFinalRenderPassDescriptor = MTL::RenderPassDescriptor::alloc()->init();
    m_pFinalRenderPassDescriptor->colorAttachments()->object(0)->setStoreAction( MTL::StoreActionStore );
    m_pFinalRenderPassDescriptor->depthAttachment()->setLoadAction( MTL::LoadActionLoad );
    m_pFinalRenderPassDescriptor->stencilAttachment()->setLoadAction( MTL::LoadActionLoad );
}

/// Respond to view size change
void Renderer_TraditionalDeferred::drawableSizeWillChange(const MTL::Size& size, MTL::StorageMode GBufferStorageMode)
{
    // The renderer base class allocates all GBuffers >except< lighting GBuffer (since with the
    // single-pass deferred renderer the lighting buffer is the same as the drawable)
    Renderer::drawableSizeWillChange( size, GBufferStorageMode );

    // Re-set GBuffer textures in the GBuffer render pass descriptor after they have been
    // reallocated by a resize
    m_pGBufferRenderPassDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setTexture( m_albedo_specular_GBuffer );
    m_pGBufferRenderPassDescriptor->colorAttachments()->object(RenderTargetNormal)->setTexture( m_normal_shadow_GBuffer );
    m_pGBufferRenderPassDescriptor->colorAttachments()->object(RenderTargetDepth)->setTexture( m_depth_GBuffer );
}

/// Draw directional lighting, which, with a tradition deferred renderer needs to set GBuffers as
/// textures before executing common rendering code to draw the light
void Renderer_TraditionalDeferred::drawDirectionalLight(MTL::RenderCommandEncoder* pRenderEncoder)
{
    pRenderEncoder->pushDebugGroup( AAPLSTR( "Draw Directional Light" ) );
    pRenderEncoder->setFragmentTexture( m_albedo_specular_GBuffer, RenderTargetAlbedo );
    pRenderEncoder->setFragmentTexture( m_normal_shadow_GBuffer, RenderTargetNormal );
    pRenderEncoder->setFragmentTexture( m_depth_GBuffer, RenderTargetDepth );

    Renderer::drawDirectionalLightCommon( pRenderEncoder );

    pRenderEncoder->popDebugGroup();
}

/// Setup traditional deferred rendering specific pipeline and set GBuffer textures.  Then call
/// common renderer code to apply the point lights
void Renderer_TraditionalDeferred::drawPointLights(MTL::RenderCommandEncoder* pRenderEncoder)
{
    pRenderEncoder->pushDebugGroup( AAPLSTR( "Draw Point Lights" ) );

    pRenderEncoder->setRenderPipelineState( m_pLightPipelineState );

    pRenderEncoder->setFragmentTexture( m_albedo_specular_GBuffer, RenderTargetAlbedo );
    pRenderEncoder->setFragmentTexture( m_normal_shadow_GBuffer, RenderTargetNormal );
    pRenderEncoder->setFragmentTexture( m_depth_GBuffer, RenderTargetDepth );

    // Call common base class method after setting state in the renderEncoder specific to the
    // traditional deferred renderer
    Renderer::drawPointLightsCommon( pRenderEncoder );

    pRenderEncoder->popDebugGroup();
}

/// Frame drawing routine
void Renderer_TraditionalDeferred::drawInView( bool isPaused, MTL::Drawable* pCurrentDrawable, MTL::Texture* pDepthStencilTexture )
{
    {
        MTL::CommandBuffer* pCommandBuffer = Renderer::beginFrame( isPaused );
        pCommandBuffer->setLabel( AAPLSTR( "Shadow & GBuffer Commands" ) );

        Renderer::drawShadow( pCommandBuffer );

        m_pGBufferRenderPassDescriptor->depthAttachment()->setTexture( pDepthStencilTexture );
        m_pGBufferRenderPassDescriptor->stencilAttachment()->setTexture( pDepthStencilTexture );

        MTL::RenderCommandEncoder* pRenderEncoder = pCommandBuffer->renderCommandEncoder( m_pGBufferRenderPassDescriptor );
        pRenderEncoder->setLabel( AAPLSTR( "GBuffer Generation" ) );

        Renderer::drawGBuffer( pRenderEncoder );

        pRenderEncoder->endEncoding();

        // Commit commands so that Metal can begin working on nondrawable dependent work without
        // waiting for a drawable to become available
        pCommandBuffer->commit();
    }

    {
        MTL::CommandBuffer* pCommandBuffer = Renderer::beginDrawableCommands();

        pCommandBuffer->setLabel( AAPLSTR( "Lighting Commands" ) );

        MTL::Texture* pDrawableTexture = Renderer::currentDrawableTexture( pCurrentDrawable );

        // The final pass can only render if a drawable is available, otherwise it needs to skip
        // rendering this frame.
        if( pDrawableTexture )
        {
            // Render the lighting and composition pass

            m_pFinalRenderPassDescriptor->colorAttachments()->object(0)->setTexture( pDrawableTexture );
            m_pFinalRenderPassDescriptor->depthAttachment()->setTexture( pDepthStencilTexture );
            m_pFinalRenderPassDescriptor->stencilAttachment()->setTexture( pDepthStencilTexture );

            MTL::RenderCommandEncoder* pRenderEncoder = pCommandBuffer->renderCommandEncoder( m_pFinalRenderPassDescriptor );
            pRenderEncoder->setLabel( AAPLSTR( "Lighting & Composition Pass" ) );

            drawDirectionalLight( pRenderEncoder );

            Renderer::drawPointLightMask( pRenderEncoder );

            drawPointLights( pRenderEncoder );

            Renderer::drawSky( pRenderEncoder );

            Renderer::drawFairies( pRenderEncoder );

            pRenderEncoder->endEncoding();
        }

        Renderer::endFrame( pCommandBuffer, pCurrentDrawable );
    }
}

#if SUPPORT_BUFFER_EXAMINATION

/// Set up render targets for display when buffer examination mode enabled. Set up target for
/// optimal rendering when buffer examination mode disabled.
void Renderer_TraditionalDeferred::validateBufferExaminationMode()
{
    if( m_bufferExaminationManager->mode() )
    {
        // Clear the background of the GBuffer when examining buffers.  When rendering normally
        // clearing is wasteful, but when examining the buffers, the backgrounds appear corrupt
        // making unclear what's actually rendered to the buffers
        m_pGBufferRenderPassDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setLoadAction( MTL::LoadActionClear );
        m_pGBufferRenderPassDescriptor->colorAttachments()->object(RenderTargetNormal)->setLoadAction( MTL::LoadActionClear );
        m_pGBufferRenderPassDescriptor->colorAttachments()->object(RenderTargetDepth)->setLoadAction( MTL::LoadActionClear );

        // Store depth and stencil buffers after filling them.  This is wasteful when rendering
        // normally, but necessary to present the light mask culling view.
        m_pFinalRenderPassDescriptor->stencilAttachment()->setStoreAction( MTL::StoreActionStore );
        m_pFinalRenderPassDescriptor->depthAttachment()->setStoreAction( MTL::StoreActionStore );
    }
    else
    {
        // When exiting buffer examination mode, return to efficient state settings
        m_pFinalRenderPassDescriptor->stencilAttachment()->setStoreAction( MTL::StoreActionDontCare );
        m_pFinalRenderPassDescriptor->depthAttachment()->setStoreAction( MTL::StoreActionDontCare );
        m_pGBufferRenderPassDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setLoadAction( MTL::LoadActionDontCare );
        m_pGBufferRenderPassDescriptor->colorAttachments()->object(RenderTargetNormal)->setLoadAction( MTL::LoadActionDontCare );
        m_pGBufferRenderPassDescriptor->colorAttachments()->object(RenderTargetDepth)->setLoadAction( MTL::LoadActionDontCare );
    }
}

#endif // END SUPPORT_BUFFER_EXAMINATION 


