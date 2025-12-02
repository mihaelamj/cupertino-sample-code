  /*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of renderer class that performs Metal setup and per-frame rendering.
*/
#include "AAPLBufferExaminationManager.h"

#if SUPPORT_BUFFER_EXAMINATION

#include "AAPLShaderTypes.h"
#include "AAPLUtilities.h"
#include "AAPLRenderer.h"

#include <simd/simd.h>
#include <CoreGraphics/CGGeometry.h>
#include <QuartzCore/CAMetalDrawable.hpp>

#if TARGET_MACOS
#define ColorClass NSColor
#define MakeRect NSMakeRect
#else
#define ColorClass UIColor
#define MakeRect CGRectMake
#endif

BufferExaminationManager::BufferExaminationManager(const Renderer& renderer,
                                                   const AAPLViewAdapter& albedoGBufferView,
                                                   const AAPLViewAdapter& normalsGBufferView,
                                                   const AAPLViewAdapter& depthGBufferView,
                                                   const AAPLViewAdapter& shadowGBufferView,
                                                   const AAPLViewAdapter& finalFrameView,
                                                   const AAPLViewAdapter& specularGBufferView,
                                                   const AAPLViewAdapter& shadowMapView,
                                                   const AAPLViewAdapter& lightMaskView,
                                                   const AAPLViewAdapter& lightCoverageView,
                                                   const AAPLViewAdapter& rendererView)
: m_renderer            ( renderer )
, m_pDevice              ( renderer.device() )
, m_mode                ( ExaminationModeDisabled )
, m_albedoGBufferView   ( albedoGBufferView )
, m_normalsGBufferView  ( normalsGBufferView )
, m_depthGBufferView    ( depthGBufferView )
, m_shadowGBufferView   ( shadowGBufferView )
, m_finalFrameView      ( finalFrameView )
, m_specularGBufferView ( specularGBufferView )
, m_shadowMapView       ( shadowMapView )
, m_lightMaskView       ( lightMaskView )
, m_lightCoverageView   ( lightCoverageView )
, m_rendererView        ( rendererView )
, m_offscreenDrawable   ( nullptr )
, m_lightVolumeTarget   ( nullptr )
{
    m_allViews.emplace_front( &m_albedoGBufferView  );
    m_allViews.emplace_front( &m_normalsGBufferView );
    m_allViews.emplace_front( &m_depthGBufferView   );
    m_allViews.emplace_front( &m_shadowGBufferView  );
    m_allViews.emplace_front( &m_finalFrameView     );
    m_allViews.emplace_front( &m_specularGBufferView);
    m_allViews.emplace_front( &m_shadowMapView      );
    m_allViews.emplace_front( &m_lightMaskView      );
    m_allViews.emplace_front( &m_lightCoverageView  );
    /* Not adding the renderer view */

    for(auto pView : m_allViews)
    {
        // "Pause" the view because the `BufferExaminationManager` explicitly triggers a redraw in
        //  `BufferExaminationManager::drawAndPresentBuffersWithCommandBuffer()`.
        pView->setPaused( true );

        // Initialize other properties.
        pView->setColorPixelFormat( m_renderer.colorTargetPixelFormat() );
        pView->setHidden( true );
    }

    loadMetalState();
}

BufferExaminationManager::~BufferExaminationManager()
{
    m_offscreenDrawable->release();
    m_lightVolumeTarget->release();
    m_lightVolumeVisualizationPipelineState->release();
    m_textureRGBPipelineState->release();
    m_textureAlphaPipelineState->release();
    m_textureDepthPipelineState->release();
    m_depthTestOnlyDepthStencilState->release();
}

void BufferExaminationManager::loadMetalState()
{
    NS::Error* pError = nullptr;

    MTL::Library* pShaderLibrary = m_pDevice->newDefaultLibrary();

    #pragma mark Light volume visualization render pipeline setup
    {
        MTL::Function* pVertexFunction   = pShaderLibrary->newFunction( AAPLSTR( "light_volume_visualization_vertex" ) );
        MTL::Function* pFragmentFunction = pShaderLibrary->newFunction( AAPLSTR( "light_volume_visualization_fragment" ) );

        AAPL_ASSERT( pVertexFunction, "Failed to load light_volume_visualization_vertex shader" );
        AAPL_ASSERT( pFragmentFunction, "Failed to load light_volume_visualization_fragment shader" );

        MTL::RenderPipelineDescriptor* pRenderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();

        pRenderPipelineDescriptor->setLabel( AAPLSTR( "Light Volume Visualization" ) );
        pRenderPipelineDescriptor->setVertexDescriptor( nullptr );
        pRenderPipelineDescriptor->setVertexFunction( pVertexFunction );
        pRenderPipelineDescriptor->setFragmentFunction( pFragmentFunction );
        pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetLighting)->setPixelFormat( m_renderer.colorTargetPixelFormat() );
        pRenderPipelineDescriptor->setDepthAttachmentPixelFormat( m_renderer.depthStencilTargetPixelFormat() );
        pRenderPipelineDescriptor->setStencilAttachmentPixelFormat( m_renderer.depthStencilTargetPixelFormat() );

        m_lightVolumeVisualizationPipelineState = m_pDevice->newRenderPipelineState( pRenderPipelineDescriptor, &pError);

        AAPL_ASSERT_NULL_ERROR( pError, "Failed to create light volume visualization render pipeline state" );
        
        pVertexFunction->release();
        pFragmentFunction->release();
        pRenderPipelineDescriptor->release();
    }

    #pragma mark Raw GBuffer visualization pipeline setup
    {
        MTL::Function* pVertexFunction   = pShaderLibrary->newFunction( AAPLSTR( "texture_values_vertex" ) );
        MTL::Function* pFragmentFunction = pShaderLibrary->newFunction( AAPLSTR( "texture_rgb_fragment" ) );

        AAPL_ASSERT( pVertexFunction, "Failed to load texture_values_vertex shader" );
        AAPL_ASSERT( pFragmentFunction, "Failed to load texture_rgb_fragment shader" );

        // Create simple pipelines that render either the RGB or Alpha components of a texture.
        MTL::RenderPipelineDescriptor* pRenderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();

        pRenderPipelineDescriptor->setLabel( AAPLSTR( "Light Volume Visualization" ) );
        pRenderPipelineDescriptor->setVertexDescriptor( nullptr );
        pRenderPipelineDescriptor->setVertexFunction( pVertexFunction );
        pRenderPipelineDescriptor->setFragmentFunction( pFragmentFunction );
        pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetLighting)->setPixelFormat( m_renderer.colorTargetPixelFormat() );


        // Pipeline to render RGB components of a texture
        m_textureRGBPipelineState = m_pDevice->newRenderPipelineState( pRenderPipelineDescriptor, &pError );

        AAPL_ASSERT_NULL_ERROR( pError, "Failed to create texture RGB render pipeline state" );

        // The pipeline that renders the Alpha components of a texture (in RGB as grayscale).
        pFragmentFunction->release();
        pFragmentFunction = pShaderLibrary->newFunction( AAPLSTR( "texture_alpha_fragment" ) );

        AAPL_ASSERT( pFragmentFunction, "Failed to load texture_alpha_fragment shader" );

        pRenderPipelineDescriptor->setFragmentFunction( pFragmentFunction );
        m_textureAlphaPipelineState = m_pDevice->newRenderPipelineState( pRenderPipelineDescriptor, &pError );
        
        AAPL_ASSERT_NULL_ERROR( pError, "Failed to create texture alpha render pipeline state" );


        // The pipeline that renders Alpha components of a texture (in RGB as grayscale), but with the
        // ability to apply a range that divides the alpha value so it normalizes the grayscale value
        // to the range [0, 1].
        pFragmentFunction->release();
        pFragmentFunction = pShaderLibrary->newFunction( AAPLSTR( "texture_depth_fragment" ) );

        AAPL_ASSERT( pFragmentFunction, "Failed to load texture_depth_fragment shader" );

        pRenderPipelineDescriptor->setFragmentFunction( pFragmentFunction );
        m_textureDepthPipelineState = m_pDevice->newRenderPipelineState( pRenderPipelineDescriptor, &pError );

        AAPL_ASSERT_NULL_ERROR( pError, "Failed to create depth texture render pipeline state" );
        
        pVertexFunction->release();
        pFragmentFunction->release();
        pRenderPipelineDescriptor->release();
    }

    #pragma mark Light volume visulalization depth state setup
    {
        MTL::DepthStencilDescriptor* pDepthStencilDesc = MTL::DepthStencilDescriptor::alloc()->init();
        pDepthStencilDesc->setDepthWriteEnabled( false );
        pDepthStencilDesc->setDepthCompareFunction( MTL::CompareFunctionLessEqual );
        pDepthStencilDesc->setLabel( AAPLSTR( "Depth Test Only" ) );

        m_depthTestOnlyDepthStencilState = m_pDevice->newDepthStencilState( pDepthStencilDesc );
        pDepthStencilDesc->release();
    }
    
    pShaderLibrary->release();
}

void BufferExaminationManager::updateDrawableSize(MTL::Size size)
{
    MTL::TextureDescriptor* pFinalTextureDesc = MTL::TextureDescriptor::alloc()->init();

    pFinalTextureDesc->setPixelFormat( m_renderer.colorTargetPixelFormat() );
    pFinalTextureDesc->setWidth( size.width );
    pFinalTextureDesc->setHeight( size.height );
    pFinalTextureDesc->setUsage( MTL::TextureUsageRenderTarget | MTL::TextureUsageShaderRead );

    if(m_mode)
    {
        m_offscreenDrawable = m_pDevice->newTexture( pFinalTextureDesc );
        m_offscreenDrawable->setLabel( AAPLSTR( "Offscreen Drawable" ) );
    }
    else
    {
        m_offscreenDrawable->release();
        m_offscreenDrawable = nullptr;
    }

    if(m_mode & (ExaminationModeMaskedLightVolumes | ExaminationModeFullLightVolumes))
    {
        m_lightVolumeTarget = m_pDevice->newTexture( pFinalTextureDesc );
        m_lightVolumeTarget->setLabel( AAPLSTR( "Light Volume Drawable" ) );
    }
    else
    {
        m_lightVolumeTarget->release();
        m_lightVolumeTarget = nullptr;
    }
    pFinalTextureDesc->release();
}


/// Draws icosahedrons that encapsulate the point-light volumes in *red* when the caller sets `fullVolumes` to `YES`.
/// 
/// This method shows the fragments that the point light fragment shader needs to execute if the user disables culling.
/// If the user enables light culling, the method colors the fragments in *green* as it draws
/// *green* allowing user to compare the coverage
void BufferExaminationManager::renderLightVolumesExaminationWithCommandBuffer(MTL::CommandBuffer* pCommandBuffer,
                                                                              bool fullVolumes)
{
    MTL::RenderPassDescriptor* pRenderPassDescriptor = MTL::RenderPassDescriptor::alloc()->init();
    pRenderPassDescriptor->colorAttachments()->object(0)->setClearColor( MTL::ClearColor::Make(0, 0, 0, 1) );
    pRenderPassDescriptor->colorAttachments()->object(0)->setLoadAction( MTL::LoadActionClear );
    pRenderPassDescriptor->colorAttachments()->object(0)->setTexture( m_lightVolumeTarget );
    pRenderPassDescriptor->colorAttachments()->object(0)->setStoreAction( MTL::StoreActionStore );

    {
        MTL::RenderCommandEncoder* pRenderEncoder = pCommandBuffer->renderCommandEncoder( pRenderPassDescriptor );
        pRenderEncoder->setLabel( AAPLSTR( "Stenciled light volumes background" ) );

        // Start by drawing the final scene, after the app fully composites it, as the background.
        pRenderEncoder->setRenderPipelineState( m_textureRGBPipelineState );
        pRenderEncoder->setVertexBuffer( m_renderer.quadVertexBuffer(), 0, BufferIndexMeshPositions );
        pRenderEncoder->setFragmentTexture( m_offscreenDrawable, TextureIndexBaseColor );
        pRenderEncoder->drawPrimitives( MTL::PrimitiveTypeTriangle, (NS::UInteger)0, (NS::UInteger)6 );

        pRenderEncoder->endEncoding();
    }

    pRenderPassDescriptor->depthAttachment()->setTexture( m_rendererView.depthStencilTexture() );
    pRenderPassDescriptor->stencilAttachment()->setTexture( m_rendererView.depthStencilTexture() );
    pRenderPassDescriptor->colorAttachments()->object(0)->setLoadAction( MTL::LoadActionLoad );
    pRenderPassDescriptor->depthAttachment()->setLoadAction( MTL::LoadActionLoad );
    pRenderPassDescriptor->stencilAttachment()->setLoadAction( MTL::LoadActionLoad );

    {
        MTL::RenderCommandEncoder* pRenderEncoder = pCommandBuffer->renderCommandEncoder( pRenderPassDescriptor );
        pRenderEncoder->setLabel( AAPLSTR( "Stenciled light volumes" ) );

        // Set the encoder to use a simple pipeline that just draws a single color.
        pRenderEncoder->setRenderPipelineState( m_lightVolumeVisualizationPipelineState );
        pRenderEncoder->setVertexBuffer( m_renderer.frameDataBuffer( m_renderer.frameDataBufferIndex() ), 0, BufferIndexFrameData );
        pRenderEncoder->setVertexBuffer( m_renderer.lightsData(), 0, BufferIndexLightsData );
        pRenderEncoder->setVertexBuffer( m_renderer.lightPositions( m_renderer.frameDataBufferIndex() ), 0, BufferIndexLightsPosition );

        const std::vector<MeshBuffer>& icoshedronVertexBuffers = m_renderer.icosahedronMesh().vertexBuffers();
        pRenderEncoder->setVertexBuffer( icoshedronVertexBuffers[0].buffer(), icoshedronVertexBuffers[0].offset(), BufferIndexMeshPositions );

        const Mesh& icosahedronMesh = m_renderer.icosahedronMesh();
        const std::vector<Submesh> & icosahedronSubmesh = icosahedronMesh.submeshes();

        if(fullVolumes || !LIGHT_STENCIL_CULLING)
        {
            // Set the depth stencil state to use a stencil test to cull fragments.
            pRenderEncoder->setDepthStencilState( m_depthTestOnlyDepthStencilState );

            // Set fragment function's output to red.
            simd::float4 redColor = { 1, 0, 0, 1 };
            pRenderEncoder->setFragmentBytes( &redColor, sizeof(redColor), BufferIndexFlatColor );

            pRenderEncoder->drawIndexedPrimitives(icosahedronSubmesh[0].primitiveType(),
                                                  icosahedronSubmesh[0].indexCount(),
                                                  icosahedronSubmesh[0].indexType(),
                                                  icosahedronSubmesh[0].indexBuffer().buffer(),
                                                  icosahedronSubmesh[0].indexBuffer().offset(),
                                                  NumLights);
        }

#if LIGHT_STENCIL_CULLING

        // Set fragment function's output to green.
        simd::float4 greenColor = { 0, 1, 0, 1 };
        pRenderEncoder->setFragmentBytes( &greenColor, sizeof(greenColor), BufferIndexFlatColor );

        // Set the depth stencil state to use a stencil test to cull fragments.
        pRenderEncoder->setDepthStencilState( m_renderer.pointLightDepthStencilState() );

        pRenderEncoder->setCullMode( MTL::CullModeBack );

        pRenderEncoder->setStencilReferenceValue( 128 );

        pRenderEncoder->drawIndexedPrimitives(icosahedronSubmesh[0].primitiveType(),
                                              icosahedronSubmesh[0].indexCount(),
                                              icosahedronSubmesh[0].indexType(),
                                              icosahedronSubmesh[0].indexBuffer().buffer(),
                                              icosahedronSubmesh[0].indexBuffer().offset(),
                                              NumLights);
#endif // END LIGHT_STENCIL_CULLING

        pRenderEncoder->endEncoding();
    }
    
    pRenderPassDescriptor->release();

}

void BufferExaminationManager::drawAlbedoGBufferWithCommandBuffer(MTL::CommandBuffer* pCommandBuffer)
{
    MTL::RenderPassDescriptor* currentRenderPassDescriptor = m_albedoGBufferView.currentRenderPassDescriptor();

    MTL::RenderCommandEncoder* pRenderEncoder = pCommandBuffer->renderCommandEncoder( currentRenderPassDescriptor );

    MTL::RenderPassColorAttachmentDescriptor* pAttachmentDesc =
        m_albedoGBufferView.currentRenderPassDescriptor()->colorAttachments()->object(0);

    MTL::Texture* pTexture = pAttachmentDesc->texture();

    pTexture->setLabel( AAPLSTR( "m_albedoGBufferViewDrawable" ) );
    pRenderEncoder->setLabel( AAPLSTR( "drawAlbedoGBufferWithCommandBuffer" ) );
    pRenderEncoder->setRenderPipelineState( m_textureRGBPipelineState );
    pRenderEncoder->setVertexBuffer( m_renderer.quadVertexBuffer(), 0, BufferIndexMeshPositions );
    pRenderEncoder->setFragmentTexture( m_renderer.albedo_specular_GBuffer(), TextureIndexBaseColor );
    pRenderEncoder->drawPrimitives( MTL::PrimitiveTypeTriangle, (NS::UInteger)0, (NS::UInteger)6 );
    pRenderEncoder->endEncoding();
}

void BufferExaminationManager::drawNormalsGBufferWithCommandBuffer(MTL::CommandBuffer* pCommandBuffer)
{
    MTL::RenderCommandEncoder* pRenderEncoder = pCommandBuffer->renderCommandEncoder( m_normalsGBufferView.currentRenderPassDescriptor() );
    pRenderEncoder->setLabel( AAPLSTR( "drawNormalsGBufferWithCommandBuffer" ) );
    pRenderEncoder->setRenderPipelineState( m_textureRGBPipelineState );
    pRenderEncoder->setVertexBuffer( m_renderer.quadVertexBuffer(), 0, BufferIndexMeshPositions );
    pRenderEncoder->setFragmentTexture( m_renderer.normal_shadow_GBuffer(), TextureIndexBaseColor );
    pRenderEncoder->drawPrimitives( MTL::PrimitiveTypeTriangle, (NS::UInteger)0, (NS::UInteger)6 );
    pRenderEncoder->endEncoding();
}

void BufferExaminationManager::drawDepthGBufferWithCommandBuffer(MTL::CommandBuffer* pCommandBuffer)
{
    MTL::RenderCommandEncoder* pRenderEncoder = pCommandBuffer->renderCommandEncoder( m_depthGBufferView.currentRenderPassDescriptor() );
    pRenderEncoder->setLabel( AAPLSTR( "drawDepthGBufferWithCommandBuffer" ) );
    pRenderEncoder->setRenderPipelineState( m_textureDepthPipelineState );
    pRenderEncoder->setVertexBuffer( m_renderer.quadVertexBuffer(), 0, BufferIndexMeshPositions );
    pRenderEncoder->setFragmentTexture( m_renderer.depth_GBuffer(), TextureIndexBaseColor );
#if USE_EYE_DEPTH
    float depthRange = FarPlane - NearPlane;
#else
    float depthRange = 1.0;
#endif
    pRenderEncoder->setFragmentBytes( &depthRange, sizeof(depthRange), BufferIndexDepthRange );
    pRenderEncoder->drawPrimitives( MTL::PrimitiveTypeTriangle, (NS::UInteger)0, (NS::UInteger)6 );
    pRenderEncoder->endEncoding();
}

void BufferExaminationManager::drawShadowGBufferWithCommandBuffer(MTL::CommandBuffer* pCommandBuffer)
{
    MTL::RenderCommandEncoder* pRenderEncoder = pCommandBuffer->renderCommandEncoder( m_shadowGBufferView.currentRenderPassDescriptor() );
    pRenderEncoder->setLabel( AAPLSTR( "drawShadowGBufferWithCommandBuffer" ) );
    pRenderEncoder->setRenderPipelineState( m_textureAlphaPipelineState );
    pRenderEncoder->setVertexBuffer( m_renderer.quadVertexBuffer(), 0, BufferIndexMeshPositions );
    pRenderEncoder->setFragmentTexture( m_renderer.normal_shadow_GBuffer(), TextureIndexBaseColor );
    pRenderEncoder->drawPrimitives( MTL::PrimitiveTypeTriangle, (NS::UInteger)0, (NS::UInteger)6 );
    pRenderEncoder->endEncoding();
}

void BufferExaminationManager::drawFinalRenderWithCommandBuffer(MTL::CommandBuffer* pCommandBuffer)
{
    MTL::RenderCommandEncoder* pRenderEncoder = pCommandBuffer->renderCommandEncoder( m_finalFrameView.currentRenderPassDescriptor() );
    pRenderEncoder->setLabel( AAPLSTR( "drawFinalRenderWithCommandBuffer" ) );
    pRenderEncoder->setRenderPipelineState( m_textureRGBPipelineState );
    pRenderEncoder->setVertexBuffer( m_renderer.quadVertexBuffer(), 0, BufferIndexMeshPositions );
    pRenderEncoder->setFragmentTexture( m_offscreenDrawable, TextureIndexBaseColor );
    pRenderEncoder->drawPrimitives( MTL::PrimitiveTypeTriangle, (NS::UInteger)0, (NS::UInteger)6 );
    pRenderEncoder->endEncoding();
}


void BufferExaminationManager::drawSpecularGBufferWithCommandBuffer(MTL::CommandBuffer* pCommandBuffer)
{
    MTL::RenderCommandEncoder* pRenderEncoder = pCommandBuffer->renderCommandEncoder( m_specularGBufferView.currentRenderPassDescriptor() );
    pRenderEncoder->setLabel( AAPLSTR( "drawSpecularGBufferWithCommandBuffer" ) );
    pRenderEncoder->setRenderPipelineState( m_textureAlphaPipelineState );
    pRenderEncoder->setVertexBuffer( m_renderer.quadVertexBuffer(), 0, BufferIndexMeshPositions );
    pRenderEncoder->setFragmentTexture( m_renderer.albedo_specular_GBuffer(), TextureIndexBaseColor );
    pRenderEncoder->drawPrimitives( MTL::PrimitiveTypeTriangle, (NS::UInteger)0, (NS::UInteger)6 );
    pRenderEncoder->endEncoding();
}

void BufferExaminationManager::drawShadowMapWithCommandBuffer(MTL::CommandBuffer* pCommandBuffer)
{
    MTL::RenderCommandEncoder* pRenderEncoder = pCommandBuffer->renderCommandEncoder( m_shadowMapView.currentRenderPassDescriptor() );
    pRenderEncoder->setLabel( AAPLSTR( "drawShadowMapWithCommandBuffer" ) );
    float depthRange = 1.0;
    pRenderEncoder->setFragmentBytes( &depthRange, sizeof(depthRange), BufferIndexDepthRange );
    pRenderEncoder->setRenderPipelineState( m_textureDepthPipelineState );
    pRenderEncoder->setVertexBuffer( m_renderer.quadVertexBuffer(), 0, BufferIndexMeshPositions );
    pRenderEncoder->setFragmentTexture( m_renderer.shadowMap(), TextureIndexBaseColor );
    pRenderEncoder->drawPrimitives( MTL::PrimitiveTypeTriangle, (NS::UInteger)0, (NS::UInteger)6 );
    pRenderEncoder->endEncoding();
}

void BufferExaminationManager::drawLightMaskWithCommandBuffer(MTL::CommandBuffer* pCommandBuffer)
{
    renderLightVolumesExaminationWithCommandBuffer( pCommandBuffer, false );

    MTL::RenderCommandEncoder* pRenderEncoder = pCommandBuffer->renderCommandEncoder( m_lightMaskView.currentRenderPassDescriptor() );
    pRenderEncoder->setLabel( AAPLSTR( "drawLightMaskWithCommandBuffer" ) );
    pRenderEncoder->setRenderPipelineState( m_textureRGBPipelineState );
    pRenderEncoder->setVertexBuffer( m_renderer.quadVertexBuffer(), 0, BufferIndexMeshPositions );
    pRenderEncoder->setFragmentTexture( m_lightVolumeTarget, TextureIndexBaseColor );
    pRenderEncoder->drawPrimitives( MTL::PrimitiveTypeTriangle, (NS::UInteger)0, (NS::UInteger)6 );
    pRenderEncoder->endEncoding();
}

void BufferExaminationManager::drawLightVolumesWithCommandBuffer(MTL::CommandBuffer* pCommandBuffer)
{
    renderLightVolumesExaminationWithCommandBuffer( pCommandBuffer, true );

    MTL::RenderCommandEncoder* pRenderEncoder = pCommandBuffer->renderCommandEncoder( m_lightCoverageView.currentRenderPassDescriptor() );
    pRenderEncoder->setLabel( AAPLSTR( "drawLightVolumesWithCommandBuffer" ) );
    pRenderEncoder->setRenderPipelineState( m_textureRGBPipelineState );
    pRenderEncoder->setVertexBuffer( m_renderer.quadVertexBuffer(), 0, BufferIndexMeshPositions );
    pRenderEncoder->setFragmentTexture( m_lightVolumeTarget, TextureIndexBaseColor );
    pRenderEncoder->drawPrimitives( MTL::PrimitiveTypeTriangle, (NS::UInteger)0, (NS::UInteger)6 );
    pRenderEncoder->endEncoding();
}

void BufferExaminationManager::mode(ExaminationMode mode)
{
    m_mode = mode;

    m_finalFrameView.setHidden     ( !(m_mode == ExaminationModeAll) );
    m_albedoGBufferView.setHidden  ( !(m_mode & ExaminationModeAlbedo) );
    m_normalsGBufferView.setHidden ( !(m_mode & ExaminationModeNormals) );
    m_depthGBufferView.setHidden   ( !(m_mode & ExaminationModeDepth) );
    m_shadowGBufferView.setHidden  ( !(m_mode & ExaminationModeShadowGBuffer) );
    m_specularGBufferView.setHidden( !(m_mode & ExaminationModeSpecular) );
    m_shadowMapView.setHidden      ( !(m_mode & ExaminationModeShadowMap) );
    m_lightMaskView.setHidden      ( !(m_mode & ExaminationModeMaskedLightVolumes) );
    m_lightCoverageView.setHidden  ( !(m_mode & ExaminationModeFullLightVolumes) );

    auto [w, h] = m_rendererView.drawableSize();
    updateDrawableSize( MTL::Size::Make(w, h, 0) );
}

void BufferExaminationManager::drawAndPresentBuffersWithCommandBuffer(MTL::CommandBuffer* pCommandBuffer)
{

    std::vector< CA::MetalDrawable* > drawablesToPresent;

    if((m_mode == ExaminationModeAll) && m_finalFrameView.currentDrawable())
    {
        drawFinalRenderWithCommandBuffer( pCommandBuffer );
        drawablesToPresent.emplace_back( m_finalFrameView.currentDrawable() );
         m_finalFrameView.draw(); // Resets MTKView currentDrawable for next frame
    }

    if((m_mode & ExaminationModeAlbedo) && m_albedoGBufferView.currentDrawable())
    {
        drawAlbedoGBufferWithCommandBuffer( pCommandBuffer );
        drawablesToPresent.emplace_back( m_albedoGBufferView.currentDrawable() );
        m_albedoGBufferView.draw(); // Resets MTKView currentDrawable for next frame
    }

    if((m_mode & ExaminationModeNormals) && m_normalsGBufferView.currentDrawable())
    {
        drawNormalsGBufferWithCommandBuffer( pCommandBuffer );
        drawablesToPresent.emplace_back( m_normalsGBufferView.currentDrawable() );
        // Reset the MetalKit view's `currentDrawable` for next frame.
	        m_normalsGBufferView.draw();
    }

    if((m_mode & ExaminationModeDepth) && m_depthGBufferView.currentDrawable())
    {
        drawDepthGBufferWithCommandBuffer( pCommandBuffer );
        drawablesToPresent.emplace_back( m_depthGBufferView.currentDrawable() );
        m_depthGBufferView.draw(); // Resets MTKView currentDrawable for next frame
    }

    if((m_mode & ExaminationModeShadowGBuffer) && m_shadowGBufferView.currentDrawable())
    {
        drawShadowGBufferWithCommandBuffer( pCommandBuffer );
        drawablesToPresent.emplace_back( m_shadowGBufferView.currentDrawable() );
        m_shadowGBufferView.draw(); // Resets MTKView currentDrawable for next frame
    }

    if((m_mode & ExaminationModeSpecular) && m_specularGBufferView.currentDrawable())
    {
        drawSpecularGBufferWithCommandBuffer( pCommandBuffer );
        drawablesToPresent.emplace_back( m_specularGBufferView.currentDrawable() );
        m_specularGBufferView.draw(); // Resets MTKView currentDrawable for next frame
    }

    if((m_mode & ExaminationModeShadowMap) && m_shadowMapView.currentDrawable())
    {
        drawShadowMapWithCommandBuffer( pCommandBuffer );
        drawablesToPresent.emplace_back( m_shadowMapView.currentDrawable() );
        m_shadowMapView.draw(); // Resets MTKView currentDrawable for next frame
    }

    if((m_mode & ExaminationModeMaskedLightVolumes) && m_lightMaskView.currentDrawable())
    {
        drawLightMaskWithCommandBuffer( pCommandBuffer );
        drawablesToPresent.emplace_back( m_lightMaskView.currentDrawable() );
        m_lightMaskView.draw(); // Resets MTKView currentDrawable for next frame
    }

    if((m_mode & ExaminationModeFullLightVolumes) && m_lightCoverageView.currentDrawable())
    {
        drawLightVolumesWithCommandBuffer( pCommandBuffer );
        drawablesToPresent.emplace_back( m_lightCoverageView.currentDrawable() );
        m_lightCoverageView.draw(); // Resets MTKView currentDrawable for next frame
    }

    for ( auto&& pDrawable : drawablesToPresent )
    {
        pDrawable->retain();
    }
    
    pCommandBuffer->addScheduledHandler([drawablesToPresent](MTL::CommandBuffer *){
        for ( auto&& pDrawable : drawablesToPresent )
        {
            pDrawable->present();
            pDrawable->release();
        }
    });

}

#endif // END SUPPORT_BUFFER_EXAMINATION
