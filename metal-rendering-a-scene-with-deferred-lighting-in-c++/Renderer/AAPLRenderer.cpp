  /*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of renderer class that performs Metal setup and per-frame rendering.
*/

#include<sys/sysctl.h>
#include <simd/simd.h>
#include <stdlib.h>

#define NS_PRIVATE_IMPLEMENTATION
#define MTL_PRIVATE_IMPLEMENTATION
#include <Metal/Metal.hpp>
#define CA_PRIVATE_IMPLEMENTATION
#include <QuartzCore/QuartzCore.hpp>


#undef NS_PRIVATE_IMPLEMENTATION
#undef CA_PRIVATE_IMPLEMENTATION
#undef MTL_PRIVATE_IMPLEMENTATION


#include "CAMetalDrawable.hpp"

#include "AAPLBufferExaminationManager.h"
#include "AAPLRenderer.h"
#include "AAPLMesh.h"
#include "AAPLMathUtilities.h"
#include "AAPLUtilities.h"

using namespace simd;

// Include header shared between C code here, which executes Metal API commands, and .metal files
#include "AAPLShaderTypes.h"

// Number of vertices in our 2D fairy model
static const uint32_t NumFairyVertices = 7;

// 30% of lights are around the tree
// 40% of lights are on the ground inside the columns
// 30% of lights are around the outside of the columns
static const uint32_t TreeLights   = 0            + 0.30 * NumLights;
static const uint32_t GroundLights = TreeLights   + 0.40 * NumLights;
static const uint32_t ColumnLights = GroundLights + 0.30 * NumLights;

Renderer::Renderer( MTL::Device* pDevice )
: m_pDevice( pDevice->retain() )
, m_originalLightPositions(nullptr)
, m_frameDataBufferIndex(0)
, m_frameNumber(0)
#if SUPPORT_BUFFER_EXAMINATION
, m_bufferExaminationManager(nullptr)
#endif
{

    this->m_inFlightSemaphore = dispatch_semaphore_create(MaxFramesInFlight);
}


Renderer::~Renderer()
{
    for(uint8_t i = 0; i < MaxFramesInFlight; i++)
    {
        m_frameDataBuffers[i]->release();
        m_lightPositions[i]->release();
    }
    
    m_pDefaultVertexDescriptor->release();
    m_pGBufferPipelineState->release();
    m_pGBufferDepthStencilState->release();
    m_pDirectionalLightPipelineState->release();
    m_pDirectionLightDepthStencilState->release();
    m_pFairyPipelineState->release();
    m_pSkyVertexDescriptor->release();
    m_pSkyboxPipelineState->release();
    m_pDontWriteDepthStencilState->release();
    m_pShadowGenPipelineState->release();
    m_pShadowDepthStencilState->release();
    m_pShadowMap->release();
    m_pShadowRenderPassDescriptor->release();
    m_pLightMaskPipelineState->release();
    m_pLightMaskDepthStencilState->release();
    m_pPointLightDepthStencilState->release();
    m_pLightsData->release();
    m_pQuadVertexBuffer->release();
    m_pFairy->release();
    m_pSkyMap->release();
    m_pFairyMap->release();
    m_albedo_specular_GBuffer->release();
    m_normal_shadow_GBuffer->release();
    m_depth_GBuffer->release();
    
    m_pCommandQueue->release();
    m_pDevice->release();
    
    delete [] m_originalLightPositions;
}

/// Create Metal render state objects
void Renderer::loadMetal()
{
    // Create and load the basic Metal state objects
    NS::Error* pError = nullptr;

    printf("Selected Device: %s\n", m_pDevice->name()->utf8String());

    for(uint8_t i = 0; i < MaxFramesInFlight; i++)
    {
        // Indicate shared storage so that both the CPU can access the buffers
        static const MTL::ResourceOptions storageMode = MTL::ResourceStorageModeShared;

        m_frameDataBuffers[i] = m_pDevice->newBuffer(sizeof(FrameData), storageMode);

        m_frameDataBuffers[i]->setLabel( AAPLSTR( "FrameData" ) );

        m_lightPositions[i] = m_pDevice->newBuffer(sizeof(float4)*NumLights, storageMode);

        m_frameDataBuffers[i]->setLabel( AAPLSTR( "LightPositions" ) );
    }

    MTL::Library* pShaderLibrary = m_pDevice->newDefaultLibrary();

    // Positions.
    m_pDefaultVertexDescriptor = MTL::VertexDescriptor::alloc()->init();
    m_pDefaultVertexDescriptor->attributes()->object(VertexAttributePosition)->setFormat( MTL::VertexFormatFloat3 );
    m_pDefaultVertexDescriptor->attributes()->object(VertexAttributePosition)->setOffset( 0 );
    m_pDefaultVertexDescriptor->attributes()->object(VertexAttributePosition)->setBufferIndex( BufferIndexMeshPositions );

    // Texture coordinates.
    m_pDefaultVertexDescriptor->attributes()->object(VertexAttributeTexcoord)->setFormat( MTL::VertexFormatFloat2 );
    m_pDefaultVertexDescriptor->attributes()->object(VertexAttributeTexcoord)->setOffset( 0 );
    m_pDefaultVertexDescriptor->attributes()->object(VertexAttributeTexcoord)->setBufferIndex( BufferIndexMeshGenerics );

    // Normals.
    m_pDefaultVertexDescriptor->attributes()->object(VertexAttributeNormal)->setFormat( MTL::VertexFormatHalf4 );
    m_pDefaultVertexDescriptor->attributes()->object(VertexAttributeNormal)->setOffset( 8 );
    m_pDefaultVertexDescriptor->attributes()->object(VertexAttributeNormal)->setBufferIndex( BufferIndexMeshGenerics );

    // Tangents
    m_pDefaultVertexDescriptor->attributes()->object(VertexAttributeTangent)->setFormat( MTL::VertexFormatHalf4 );
    m_pDefaultVertexDescriptor->attributes()->object(VertexAttributeTangent)->setOffset( 16 );
    m_pDefaultVertexDescriptor->attributes()->object(VertexAttributeTangent)->setBufferIndex( BufferIndexMeshGenerics );

    // Bitangents
    m_pDefaultVertexDescriptor->attributes()->object(VertexAttributeBitangent)->setFormat( MTL::VertexFormatHalf4 );
    m_pDefaultVertexDescriptor->attributes()->object(VertexAttributeBitangent)->setOffset( 24 );
    m_pDefaultVertexDescriptor->attributes()->object(VertexAttributeBitangent)->setBufferIndex( BufferIndexMeshGenerics );

    // Position Buffer Layout
    m_pDefaultVertexDescriptor->layouts()->object(BufferIndexMeshPositions)->setStride( 12 );
    m_pDefaultVertexDescriptor->layouts()->object(BufferIndexMeshPositions)->setStepRate( 1 );
    m_pDefaultVertexDescriptor->layouts()->object(BufferIndexMeshPositions)->setStepFunction( MTL::VertexStepFunctionPerVertex );

    // Generic Attribute Buffer Layout
    m_pDefaultVertexDescriptor->layouts()->object(BufferIndexMeshGenerics)->setStride( 32 );
    m_pDefaultVertexDescriptor->layouts()->object(BufferIndexMeshGenerics)->setStepRate( 1 );
    m_pDefaultVertexDescriptor->layouts()->object(BufferIndexMeshGenerics)->setStepFunction( MTL::VertexStepFunctionPerVertex );

    MTL::PixelFormat depthStencilPixelFormat = this->depthStencilTargetPixelFormat();
    MTL::PixelFormat colorPixelFormat = this->colorTargetPixelFormat();
    
    m_albedo_specular_GBufferFormat = MTL::PixelFormatRGBA8Unorm_sRGB;
    m_normal_shadow_GBufferFormat   = MTL::PixelFormatRGBA8Snorm;
    m_depth_GBufferFormat           = MTL::PixelFormatR32Float;

    #pragma mark GBuffer render pipeline setup
    {
        {
            MTL::Function* pGBufferVertexFunction = pShaderLibrary->newFunction( AAPLSTR( "gbuffer_vertex" ) );
            MTL::Function* pGBufferFragmentFunction = pShaderLibrary->newFunction( AAPLSTR( "gbuffer_fragment" ) );

            AAPL_ASSERT( pGBufferVertexFunction, "Failed to load gbuffer_vertex shader" );
            AAPL_ASSERT( pGBufferFragmentFunction, "Failed to load gbuffer_fragment shader" );

            MTL::RenderPipelineDescriptor* pRenderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();

            pRenderPipelineDescriptor->setLabel( AAPLSTR( "Geometry buffer render pipeline" ) );
            pRenderPipelineDescriptor->setVertexDescriptor( m_pDefaultVertexDescriptor );

            if(m_singlePassDeferred)
            {
                pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetLighting)->setPixelFormat( colorPixelFormat );
            }
            else
            {
                pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetLighting)->setPixelFormat( MTL::PixelFormatInvalid );
            }

            pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setPixelFormat( m_albedo_specular_GBufferFormat );
            pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetNormal)->setPixelFormat( m_normal_shadow_GBufferFormat );
            pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetDepth)->setPixelFormat( m_depth_GBufferFormat );
            pRenderPipelineDescriptor->setDepthAttachmentPixelFormat( depthStencilPixelFormat );
            pRenderPipelineDescriptor->setStencilAttachmentPixelFormat( depthStencilPixelFormat );

            pRenderPipelineDescriptor->setVertexFunction( pGBufferVertexFunction );
            pRenderPipelineDescriptor->setFragmentFunction( pGBufferFragmentFunction );

            m_pGBufferPipelineState = m_pDevice->newRenderPipelineState( pRenderPipelineDescriptor, &pError );

            AAPL_ASSERT_NULL_ERROR( pError, "Failed to create GBuffer render pipeline state" );
            
            pRenderPipelineDescriptor->release();
            pGBufferVertexFunction->release();
            pGBufferFragmentFunction->release();
        }

        #pragma mark GBuffer depth state setup
        {
#if LIGHT_STENCIL_CULLING
            MTL::StencilDescriptor* pStencilStateDesc = MTL::StencilDescriptor::alloc()->init();
            pStencilStateDesc->setStencilCompareFunction( MTL::CompareFunctionAlways );
            pStencilStateDesc->setStencilFailureOperation( MTL::StencilOperationKeep );
            pStencilStateDesc->setDepthFailureOperation( MTL::StencilOperationKeep );
            pStencilStateDesc->setDepthStencilPassOperation( MTL::StencilOperationReplace );
            pStencilStateDesc->setReadMask( 0x0 );
            pStencilStateDesc->setWriteMask( 0xFF );
#else
            MTL::StencilDescriptor* pStencilStateDesc = MTL::StencilDescriptor::alloc()->init();
#endif
            MTL::DepthStencilDescriptor* pDepthStencilDesc = MTL::DepthStencilDescriptor::alloc()->init();
            pDepthStencilDesc->setLabel( AAPLSTR( "Geometry buffer depth/stencil" ) );
            pDepthStencilDesc->setDepthCompareFunction( MTL::CompareFunctionLess );
            pDepthStencilDesc->setDepthWriteEnabled( true );
            pDepthStencilDesc->setFrontFaceStencil( pStencilStateDesc );
            pDepthStencilDesc->setBackFaceStencil( pStencilStateDesc );

            m_pGBufferDepthStencilState = m_pDevice->newDepthStencilState( pDepthStencilDesc );
            pDepthStencilDesc->release();
            pStencilStateDesc->release();
        }
    }

    // Setup render state to apply directional light and shadow in final pass
    {
        #pragma mark Directional lighting render pipeline setup
        {
            MTL::Function* pDirectionalVertexFunction = pShaderLibrary->newFunction( AAPLSTR( "deferred_direction_lighting_vertex" ) );
            MTL::Function* pDirectionalFragmentFunction;

            if(m_singlePassDeferred)
            {
                pDirectionalFragmentFunction =
                    pShaderLibrary->newFunction( AAPLSTR( "deferred_directional_lighting_fragment_single_pass" ) );
                AAPL_ASSERT( pDirectionalFragmentFunction, "Failed to load deferred_directional_lighting_fragment_single_pass shader" );
            }
            else
            {
                pDirectionalFragmentFunction =
                    pShaderLibrary->newFunction( AAPLSTR( "deferred_directional_lighting_fragment_traditional" ) );
                AAPL_ASSERT( pDirectionalFragmentFunction, "Failed to load deferred_directional_lighting_fragment_traditional shader" );
            }

            MTL::RenderPipelineDescriptor* pRenderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();

            pRenderPipelineDescriptor->setLabel( AAPLSTR( "Deferred Directional Lighting" ) );
            pRenderPipelineDescriptor->setVertexDescriptor( nullptr );
            pRenderPipelineDescriptor->setVertexFunction( pDirectionalVertexFunction );
            pRenderPipelineDescriptor->setFragmentFunction( pDirectionalFragmentFunction );
            pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetLighting)->setPixelFormat( colorPixelFormat );

            if(m_singlePassDeferred)
            {
                pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setPixelFormat( m_albedo_specular_GBufferFormat );
                pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetNormal)->setPixelFormat( m_normal_shadow_GBufferFormat );
                pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetDepth)->setPixelFormat( m_depth_GBufferFormat );
            }

            pRenderPipelineDescriptor->setDepthAttachmentPixelFormat( depthStencilPixelFormat );
            pRenderPipelineDescriptor->setStencilAttachmentPixelFormat( depthStencilPixelFormat);

            m_pDirectionalLightPipelineState = m_pDevice->newRenderPipelineState(pRenderPipelineDescriptor, &pError);

            AAPL_ASSERT_NULL_ERROR( pError, "Failed to create directional light render pipeline state:" );
            
            pRenderPipelineDescriptor->release();
            pDirectionalVertexFunction->release();
            pDirectionalFragmentFunction->release();
        }

        #pragma mark Directional lighting mask depth stencil state setup
        {
            MTL::StencilDescriptor* pStencilStateDesc = MTL::StencilDescriptor::alloc()->init();
#if LIGHT_STENCIL_CULLING
            // Stencil state setup so direction lighting fragment shader only executed on pixels
            // drawn in GBuffer stage (i.e. mask out the background/sky)
            pStencilStateDesc->setStencilCompareFunction( MTL::CompareFunctionEqual );
            pStencilStateDesc->setStencilFailureOperation( MTL::StencilOperationKeep );
            pStencilStateDesc->setDepthFailureOperation( MTL::StencilOperationKeep );
            pStencilStateDesc->setDepthStencilPassOperation( MTL::StencilOperationKeep );
            pStencilStateDesc->setReadMask( 0xFF );
            pStencilStateDesc->setWriteMask( 0x0 );
#endif
            MTL::DepthStencilDescriptor* pDepthStencilDesc = MTL::DepthStencilDescriptor::alloc()->init();
            pDepthStencilDesc->setLabel( AAPLSTR( "Deferred Directional Lighting" ) );
            pDepthStencilDesc->setDepthWriteEnabled( false );
            pDepthStencilDesc->setDepthCompareFunction( MTL::CompareFunctionAlways );
            pDepthStencilDesc->setFrontFaceStencil( pStencilStateDesc );
            pDepthStencilDesc->setBackFaceStencil( pStencilStateDesc );

            m_pDirectionLightDepthStencilState = m_pDevice->newDepthStencilState( pDepthStencilDesc );
            
            pDepthStencilDesc->release();
            pStencilStateDesc->release();
        }
    }

    #pragma mark Fairy billboard render pipeline setup
    {
        MTL::Function* pFairyVertexFunction = pShaderLibrary->newFunction( AAPLSTR( "fairy_vertex" ) );
        MTL::Function* pFairyFragmentFunction = pShaderLibrary->newFunction( AAPLSTR( "fairy_fragment" ) );

        AAPL_ASSERT( pFairyVertexFunction, "Failed to load fairy_vertex shader" );
        AAPL_ASSERT( pFairyFragmentFunction, "Failed to load fairy_fragment shader" );

        MTL::RenderPipelineDescriptor* pRenderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();

        pRenderPipelineDescriptor->setLabel( AAPLSTR( "Fairy Drawing" ) );
        pRenderPipelineDescriptor->setVertexDescriptor( nullptr );
        pRenderPipelineDescriptor->setVertexFunction( pFairyVertexFunction );
        pRenderPipelineDescriptor->setFragmentFunction( pFairyFragmentFunction );
        pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetLighting)->setPixelFormat( colorPixelFormat );

        // Because iOS renderer can perform GBuffer pass in final pass, any pipeline rendering in
        // the final pass must take the GBuffers into account
        if(m_singlePassDeferred)
        {
            pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setPixelFormat( m_albedo_specular_GBufferFormat );
            pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetNormal)->setPixelFormat( m_normal_shadow_GBufferFormat );
            pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetDepth)->setPixelFormat( m_depth_GBufferFormat );
        }

        pRenderPipelineDescriptor->setDepthAttachmentPixelFormat( depthStencilPixelFormat );
        pRenderPipelineDescriptor->setStencilAttachmentPixelFormat( depthStencilPixelFormat );
        pRenderPipelineDescriptor->colorAttachments()->object(0)->setBlendingEnabled( true );
        pRenderPipelineDescriptor->colorAttachments()->object(0)->setRgbBlendOperation( MTL::BlendOperationAdd );
        pRenderPipelineDescriptor->colorAttachments()->object(0)->setAlphaBlendOperation( MTL::BlendOperationAdd );
        pRenderPipelineDescriptor->colorAttachments()->object(0)->setSourceRGBBlendFactor( MTL::BlendFactorSourceAlpha );
        pRenderPipelineDescriptor->colorAttachments()->object(0)->setSourceAlphaBlendFactor ( MTL::BlendFactorSourceAlpha );
        pRenderPipelineDescriptor->colorAttachments()->object(0)->setDestinationRGBBlendFactor( MTL::BlendFactorOne );
        pRenderPipelineDescriptor->colorAttachments()->object(0)->setDestinationAlphaBlendFactor( MTL::BlendFactorOne );

        m_pFairyPipelineState = m_pDevice->newRenderPipelineState( pRenderPipelineDescriptor, &pError );

        AAPL_ASSERT_NULL_ERROR( pError, "Failed to create fairy render pipeline state:" );
        
        pRenderPipelineDescriptor->release();
        pFairyVertexFunction->release();
        pFairyFragmentFunction->release();
    }

    #pragma mark Sky render pipeline setup
    {
        m_pSkyVertexDescriptor = MTL::VertexDescriptor::alloc()->init();
        m_pSkyVertexDescriptor->attributes()->object(VertexAttributePosition)->setFormat( MTL::VertexFormatFloat3 );
        m_pSkyVertexDescriptor->attributes()->object(VertexAttributePosition)->setOffset( 0 );
        m_pSkyVertexDescriptor->attributes()->object(VertexAttributePosition)->setBufferIndex( BufferIndexMeshPositions );
        m_pSkyVertexDescriptor->layouts()->object(BufferIndexMeshPositions)->setStride( 12 );
        m_pSkyVertexDescriptor->attributes()->object(VertexAttributeNormal)->setFormat( MTL::VertexFormatFloat3 );
        m_pSkyVertexDescriptor->attributes()->object(VertexAttributeNormal)->setOffset( 0 );
        m_pSkyVertexDescriptor->attributes()->object(VertexAttributeNormal)->setBufferIndex( BufferIndexMeshGenerics );
        m_pSkyVertexDescriptor->layouts()->object(BufferIndexMeshGenerics)->setStride( 12 );

        MTL::Function* pSkyboxVertexFunction = pShaderLibrary->newFunction( AAPLSTR( "skybox_vertex" ) );
        MTL::Function* pSkyboxFragmentFunction = pShaderLibrary->newFunction( AAPLSTR( "skybox_fragment" ) );

        AAPL_ASSERT( pSkyboxVertexFunction, "Failed to load skybox_vertex shader" );
        AAPL_ASSERT( pSkyboxFragmentFunction, "Failed to load skybox_fragment shader" );

        MTL::RenderPipelineDescriptor* pRenderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
        pRenderPipelineDescriptor->setLabel( AAPLSTR( "Sky" ) );
        pRenderPipelineDescriptor->setVertexDescriptor( m_pSkyVertexDescriptor );
        pRenderPipelineDescriptor->setVertexFunction( pSkyboxVertexFunction );
        pRenderPipelineDescriptor->setFragmentFunction( pSkyboxFragmentFunction );
        pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetLighting)->setPixelFormat( colorPixelFormat );

        if(m_singlePassDeferred)
        {
            pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setPixelFormat( m_albedo_specular_GBufferFormat );
            pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetNormal)->setPixelFormat( m_normal_shadow_GBufferFormat );
            pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetDepth)->setPixelFormat( m_depth_GBufferFormat );
        }

        pRenderPipelineDescriptor->setDepthAttachmentPixelFormat( depthStencilPixelFormat );
        pRenderPipelineDescriptor->setStencilAttachmentPixelFormat( depthStencilPixelFormat );

        m_pSkyboxPipelineState = m_pDevice->newRenderPipelineState( pRenderPipelineDescriptor, &pError );

        AAPL_ASSERT_NULL_ERROR( pError, "Failed to create skybox render pipeline state:" );
        
        pRenderPipelineDescriptor->release();
        pSkyboxVertexFunction->release();
        pSkyboxFragmentFunction->release();
    }

    #pragma mark Post lighting depth state setup
    {
        MTL::DepthStencilDescriptor* pDepthStencilDesc = MTL::DepthStencilDescriptor::alloc()->init();
        pDepthStencilDesc->setLabel( AAPLSTR( "Less -Writes" ) );
        pDepthStencilDesc->setDepthCompareFunction( MTL::CompareFunctionLess );
        pDepthStencilDesc->setDepthWriteEnabled( false );

        m_pDontWriteDepthStencilState = m_pDevice->newDepthStencilState( pDepthStencilDesc );
        pDepthStencilDesc->release();
    }

    // Setup objects for shadow pass
    {
        MTL::PixelFormat shadowMapPixelFormat = MTL::PixelFormatDepth16Unorm;

        #pragma mark Shadow pass render pipeline setup
        {
            MTL::Function* pShadowVertexFunction = pShaderLibrary->newFunction( AAPLSTR( "shadow_vertex" ) );

            AAPL_ASSERT( pShadowVertexFunction, "Failed to load shadow_vertex shader" );

            MTL::RenderPipelineDescriptor* pRenderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
            pRenderPipelineDescriptor->setLabel( AAPLSTR( "Shadow Gen" ) );
            pRenderPipelineDescriptor->setVertexDescriptor( nullptr );
            pRenderPipelineDescriptor->setVertexFunction( pShadowVertexFunction );
            pRenderPipelineDescriptor->setFragmentFunction( nullptr );
            pRenderPipelineDescriptor->setDepthAttachmentPixelFormat( shadowMapPixelFormat );

            m_pShadowGenPipelineState = m_pDevice->newRenderPipelineState( pRenderPipelineDescriptor, &pError );
            
            AAPL_ASSERT_NULL_ERROR( pError, "Failed to create shadow map render pipeline state:");

            pRenderPipelineDescriptor->release();
            pShadowVertexFunction->release();
            
        }

        #pragma mark Shadow pass depth state setup
        {
            MTL::DepthStencilDescriptor* pDepthStencilDesc = MTL::DepthStencilDescriptor::alloc()->init();
            pDepthStencilDesc->setLabel( AAPLSTR( "Shadow Gen" ) );
            pDepthStencilDesc->setDepthCompareFunction( MTL::CompareFunctionLessEqual );
            pDepthStencilDesc->setDepthWriteEnabled( true );
            m_pShadowDepthStencilState = m_pDevice->newDepthStencilState( pDepthStencilDesc );
            pDepthStencilDesc->release();
        }

        #pragma mark Shadow map setup
        {
            MTL::TextureDescriptor* pShadowTextureDesc = MTL::TextureDescriptor::alloc()->init();

            pShadowTextureDesc->setPixelFormat( shadowMapPixelFormat );
            pShadowTextureDesc->setWidth( 2048 );
            pShadowTextureDesc->setHeight( 2048 );
            pShadowTextureDesc->setMipmapLevelCount( 1 );
            pShadowTextureDesc->setResourceOptions( MTL::ResourceStorageModePrivate );
            pShadowTextureDesc->setUsage( MTL::TextureUsageRenderTarget | MTL::TextureUsageShaderRead );

            m_pShadowMap = m_pDevice->newTexture( pShadowTextureDesc );
            m_pShadowMap->setLabel( AAPLSTR( "Shadow Map" ) );
            
            pShadowTextureDesc->release();
        }

        #pragma mark Shadow render pass descriptor setup
        {
            m_pShadowRenderPassDescriptor = MTL::RenderPassDescriptor::alloc()->init();
            m_pShadowRenderPassDescriptor->depthAttachment()->setTexture( m_pShadowMap );
            m_pShadowRenderPassDescriptor->depthAttachment()->setLoadAction( MTL::LoadActionClear );
            m_pShadowRenderPassDescriptor->depthAttachment()->setStoreAction( MTL::StoreActionStore );
            m_pShadowRenderPassDescriptor->depthAttachment()->setClearDepth( 1.0 );
        }

        // Calculate projection matrix to render shadows
        {
            m_shadowProjectionMatrix = matrix_ortho_left_hand(-53, 53, -33, 53, -53, 53);
        }
    }

#if LIGHT_STENCIL_CULLING
    // Setup objects for point light mask rendering
    {
        #pragma mark Light mask render pipeline state setup
        {
            MTL::Function* pLightMaskVertex = pShaderLibrary->newFunction( AAPLSTR( "light_mask_vertex" ) );

            AAPL_ASSERT( pLightMaskVertex, "Failed to load light_mask_vertex shader" );

            MTL::RenderPipelineDescriptor* pRenderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
            pRenderPipelineDescriptor->setLabel( AAPLSTR( "Point Light Mask" ) );
            pRenderPipelineDescriptor->setVertexDescriptor( nullptr );
            pRenderPipelineDescriptor->setVertexFunction( pLightMaskVertex );
            pRenderPipelineDescriptor->setFragmentFunction( nullptr );
            pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetLighting)->setPixelFormat( colorPixelFormat );

            if(m_singlePassDeferred)
            {
                pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetAlbedo)->setPixelFormat( m_albedo_specular_GBufferFormat );
                pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetNormal)->setPixelFormat( m_normal_shadow_GBufferFormat );
                pRenderPipelineDescriptor->colorAttachments()->object(RenderTargetDepth)->setPixelFormat( m_depth_GBufferFormat );
            }

            pRenderPipelineDescriptor->setDepthAttachmentPixelFormat( depthStencilPixelFormat );
            pRenderPipelineDescriptor->setStencilAttachmentPixelFormat( depthStencilPixelFormat );

            m_pLightMaskPipelineState = m_pDevice->newRenderPipelineState( pRenderPipelineDescriptor, &pError );

            AAPL_ASSERT_NULL_ERROR( pError, "Failed to create directional light mask pipeline state:" );
            
            pRenderPipelineDescriptor->release();
            pLightMaskVertex->release();
        }

        #pragma mark Light mask depth stencil state setup
        {
            MTL::StencilDescriptor* pStencilStateDesc = MTL::StencilDescriptor::alloc()->init();
            pStencilStateDesc->setStencilCompareFunction( MTL::CompareFunctionAlways );
            pStencilStateDesc->setStencilFailureOperation( MTL::StencilOperationKeep );
            pStencilStateDesc->setDepthFailureOperation( MTL::StencilOperationIncrementClamp );
            pStencilStateDesc->setDepthStencilPassOperation( MTL::StencilOperationKeep );
            pStencilStateDesc->setReadMask( 0x0 );
            pStencilStateDesc->setWriteMask( 0xFF );
            
            MTL::DepthStencilDescriptor* pDepthStencilDesc = MTL::DepthStencilDescriptor::alloc()->init();
            pDepthStencilDesc->setLabel( AAPLSTR( "Point Light Mask" ) );
            pDepthStencilDesc->setDepthWriteEnabled( false );
            pDepthStencilDesc->setDepthCompareFunction( MTL::CompareFunctionLessEqual );
            pDepthStencilDesc->setFrontFaceStencil( pStencilStateDesc );
            pDepthStencilDesc->setBackFaceStencil( pStencilStateDesc );

            m_pLightMaskDepthStencilState = m_pDevice->newDepthStencilState( pDepthStencilDesc );
            
            pDepthStencilDesc->release();
            pStencilStateDesc->release();
        }
    }
#endif // END LIGHT_STENCIL_CULLING

    #pragma mark Point light depth state setup
    {
        MTL::StencilDescriptor* pStencilStateDesc = MTL::StencilDescriptor::alloc()->init();
#if LIGHT_STENCIL_CULLING
        pStencilStateDesc->setStencilCompareFunction( MTL::CompareFunctionLess );
        pStencilStateDesc->setStencilFailureOperation( MTL::StencilOperationKeep );
        pStencilStateDesc->setDepthFailureOperation( MTL::StencilOperationKeep );
        pStencilStateDesc->setDepthStencilPassOperation( MTL::StencilOperationKeep );
        pStencilStateDesc->setReadMask( 0xFF );
        pStencilStateDesc->setWriteMask( 0x0 );
#endif // END NOT LIGHT_STENCIL_CULLING
        MTL::DepthStencilDescriptor* pDepthStencilDesc = MTL::DepthStencilDescriptor::alloc()->init();
        pDepthStencilDesc->setDepthWriteEnabled( false );
        pDepthStencilDesc->setDepthCompareFunction( MTL::CompareFunctionLessEqual );
        pDepthStencilDesc->setFrontFaceStencil( pStencilStateDesc );
        pDepthStencilDesc->setBackFaceStencil( pStencilStateDesc );
        pDepthStencilDesc->setLabel( AAPLSTR( "Point Light" ) );

        m_pPointLightDepthStencilState = m_pDevice->newDepthStencilState( pDepthStencilDesc );
        
        pDepthStencilDesc->release();
        pStencilStateDesc->release();
    }

    pShaderLibrary->release();
    m_pCommandQueue = m_pDevice->newCommandQueue();
}

/// Load models/textures, etc.
void Renderer::loadScene()
{
    // Create and load assets into Metal objects including meshes and textures
    NS::Error* pError = nullptr;

    m_meshes = newMeshesFromBundlePath("Meshes/Temple.obj", m_pDevice, *m_pDefaultVertexDescriptor, &pError);

    AAPL_ASSERT_NULL_ERROR( pError, "Could not create meshes from model file" );

    // Generate data
    {
        m_pLightsData = m_pDevice->newBuffer( sizeof(PointLight) * NumLights, MTL::ResourceStorageModeShared );

        m_pLightsData->setLabel( AAPLSTR( "LightData" ) );

        populateLights();
    }

    // Create quad for fullscreen composition drawing
    {
        static const SimpleVertex quadVertices[] =
        {
            { { -1.0f,  -1.0f, } },
            { { -1.0f,   1.0f, } },
            { {  1.0f,  -1.0f, } },

            { {  1.0f,  -1.0f, } },
            { { -1.0f,   1.0f, } },
            { {  1.0f,   1.0f, } },
        };

        m_pQuadVertexBuffer = m_pDevice->newBuffer( quadVertices, sizeof(quadVertices), MTL::ResourceStorageModeShared );

        m_pQuadVertexBuffer->setLabel( AAPLSTR( "Quad Vertices" ) );
    }

    // Create a simple 2D triangle strip circle mesh for fairies
    {
        SimpleVertex fairyVertices[NumFairyVertices];
        const float angle = 2*M_PI/(float)NumFairyVertices;
        for(int vtx = 0; vtx < NumFairyVertices; vtx++)
        {
            int point = (vtx%2) ? (vtx+1)/2 : -vtx/2;
            float2 position = {sin(point*angle), cos(point*angle)};
            fairyVertices[vtx].position = position;
        }

        m_pFairy = m_pDevice->newBuffer(fairyVertices, sizeof(fairyVertices), MTL::ResourceStorageModeShared);

        m_pFairy->setLabel( AAPLSTR( "Fairy Vertices" ) );
    }

    // Create an icosahedron mesh for fairy light volumes
    {
        // Create vertex descriptor with layout for icoshedron
        MTL::VertexDescriptor* pIcosahedronDescriptor = MTL::VertexDescriptor::alloc()->init();
        pIcosahedronDescriptor->attributes()->object(VertexAttributePosition)->setFormat( MTL::VertexFormatFloat4 );
        pIcosahedronDescriptor->attributes()->object(VertexAttributePosition)->setOffset( 0 );
        pIcosahedronDescriptor->attributes()->object(VertexAttributePosition)->setBufferIndex( BufferIndexMeshPositions );

        pIcosahedronDescriptor->layouts()->object(BufferIndexMeshPositions)->setStride ( sizeof(float4) );

        // Calculate radius such that minimum radius of icosahedronDescriptor is 1
        const float icoshedronRadius = 1.0 / (sqrtf(3.0) / 12.0 * (3.0 + sqrtf(5.0)));

        m_icosahedronMesh = makeIcosahedronMesh(m_pDevice, *pIcosahedronDescriptor, icoshedronRadius);
        
        pIcosahedronDescriptor->release();
    }

    // Create a sphere for the skybox
    {
        m_skyMesh = makeSphereMesh(m_pDevice, *m_pSkyVertexDescriptor, 20, 20, 150.0 );
    }

    // Load textures for nonmesh assets.
    {
        m_pSkyMap = newTextureFromCatalog( m_pDevice, "SkyMap", MTL::StorageModePrivate, MTL::TextureUsageShaderRead );
        m_pFairyMap = newTextureFromCatalog( m_pDevice, "FairyMap", MTL::StorageModePrivate, MTL::TextureUsageShaderRead );
    }
}

/// Initialize light positions and colors
void Renderer::populateLights()
{
    PointLight *light_data = (PointLight*)m_pLightsData->contents();

    m_originalLightPositions = new float4[ NumLights ];

    float4 *light_position = m_originalLightPositions;

    srandom(0x134e5348);

    for(uint32_t lightId = 0; lightId < NumLights; lightId++)
    {
        float distance = 0;
        float height = 0;
        float angle = 0;
        float speed = 0;

        if(lightId < TreeLights)
        {
            distance = random_float(38,42);
            height = random_float(0,1);
            angle = random_float(0, M_PI*2);
            speed = random_float(0.003,0.014);
        }
        else if(lightId < GroundLights)
        {
            distance = random_float(140,260);
            height = random_float(140,150);
            angle = random_float(0, M_PI*2);
            speed = random_float(0.006,0.027);
            speed *= (random()%2)*2-1;
        }
        else if(lightId < ColumnLights)
        {
            distance = random_float(365,380);
            height = random_float(150,190);
            angle = random_float(0, M_PI*2);
            speed = random_float(0.004,0.014);
            speed *= (random()%2)*2-1;
        }

        speed *= .5;
        *light_position = (float4){ distance*sinf(angle),height,distance*cosf(angle),1};
        light_data->light_radius = random_float(25,35)/10.0;
        light_data->light_speed  = speed;

        int colorId = random()%3;
        if( colorId == 0) {
            light_data->light_color = (float3){random_float(4,6),random_float(0,4),random_float(0,4)};
        } else if ( colorId == 1) {
            light_data->light_color = (float3){random_float(0,4),random_float(4,6),random_float(0,4)};
        } else {
            light_data->light_color = (float3){random_float(0,4),random_float(0,4),random_float(4,6)};
        }

        light_data++;
        light_position++;
    }
}

/// Update light positions
void Renderer::updateLights(const float4x4 & modelViewMatrix)
{
    PointLight *lightData = (PointLight*)m_pLightsData->contents();

    float4 *currentBuffer =
        (float4*) m_lightPositions[m_frameDataBufferIndex]->contents();

    float4 *originalLightPositions =  (float4 *)m_originalLightPositions;

    for(int i = 0; i < NumLights; i++)
    {
        float4 currentPosition;

        if(i < TreeLights)
        {
            double lightPeriod = lightData[i].light_speed  * m_frameNumber;
            lightPeriod += originalLightPositions[i].y;
            lightPeriod -= floor(lightPeriod);  // Get fractional part

            // Use pow to slowly move the light outward as it reaches the branches of the tree
            float r = 1.2 + 10.0 * powf(lightPeriod, 5.0);

            currentPosition.x = originalLightPositions[i].x * r;
            currentPosition.y = 200.0f + lightPeriod * 400.0f;
            currentPosition.z = originalLightPositions[i].z * r;
            currentPosition.w = 1;
        }
        else
        {
            float rotationRadians = lightData[i].light_speed * m_frameNumber;
            float4x4 rotation = matrix4x4_rotation(rotationRadians, 0, 1, 0);
            currentPosition = rotation * originalLightPositions[i];
        }

        currentPosition = modelViewMatrix * currentPosition;
        currentBuffer[i] = currentPosition;
    }
}

/// Update application state for the current frame
void Renderer::updateWorldState( bool isPaused )
{
    if(!isPaused)
    {
        m_frameNumber++;
    }
    m_frameDataBufferIndex = (m_frameDataBufferIndex+1) % MaxFramesInFlight;

    FrameData *frameData = (FrameData *) (m_frameDataBuffers[m_frameDataBufferIndex]->contents());

    // Set projection matrix and calculate inverted projection matrix
    frameData->projection_matrix = m_projection_matrix;
    frameData->projection_matrix_inverse = matrix_invert(m_projection_matrix);

    // Set screen dimensions
    frameData->framebuffer_width = (uint)m_albedo_specular_GBuffer->width();
    frameData->framebuffer_height = (uint)m_albedo_specular_GBuffer->height();

    frameData->shininess_factor = 1;
    frameData->fairy_specular_intensity = 32;

    float cameraRotationRadians = m_frameNumber * 0.0025f + M_PI;

    float3 cameraRotationAxis = {0, 1, 0};
    float4x4 cameraRotationMatrix = matrix4x4_rotation(cameraRotationRadians, cameraRotationAxis);

    float4x4 view_matrix = matrix_look_at_left_hand(0,  18, -50,
                                                    0,   5,   0,
                                                    0 ,  1,   0);

    view_matrix = view_matrix * cameraRotationMatrix;

    frameData->view_matrix = view_matrix;

    float4x4 templeScaleMatrix = matrix4x4_scale(0.1, 0.1, 0.1);
    float4x4 templeTranslateMatrix = matrix4x4_translation(0, -10, 0);
    float4x4 templeModelMatrix = templeTranslateMatrix * templeScaleMatrix;
    frameData->temple_model_matrix = templeModelMatrix;
    frameData->temple_modelview_matrix = frameData->view_matrix * templeModelMatrix;
    frameData->temple_normal_matrix = matrix3x3_upper_left(frameData->temple_modelview_matrix);

    float skyRotation = m_frameNumber * 0.005f - (M_PI_4*3);

    float3 skyRotationAxis = {0, 1, 0};
    float4x4 skyModelMatrix = matrix4x4_rotation(skyRotation, skyRotationAxis);
    frameData->sky_modelview_matrix = cameraRotationMatrix * skyModelMatrix;

    // Update directional light color
    float4 sun_color = {0.5, 0.5, 0.5, 1.0};
    frameData->sun_color = sun_color;
    frameData->sun_specular_intensity = 1;

    // Update sun direction in view space
    float4 sunModelPosition = {-0.25, -0.5, 1.0, 0.0};

    float4 sunWorldPosition = skyModelMatrix * sunModelPosition;

    float4 sunWorldDirection = -sunWorldPosition;

    frameData->sun_eye_direction = view_matrix * sunWorldDirection;

    {
        float4 directionalLightUpVector = {0.0, 1.0, 1.0, 1.0};

        directionalLightUpVector = skyModelMatrix * directionalLightUpVector;
        directionalLightUpVector.xyz = normalize(directionalLightUpVector.xyz);

        float4x4 shadowViewMatrix = matrix_look_at_left_hand(sunWorldDirection.xyz / 10,
                                                                    (float3){0,0,0},
                                                                    directionalLightUpVector.xyz);

        float4x4 shadowModelViewMatrix = shadowViewMatrix * templeModelMatrix;

        frameData->shadow_mvp_matrix = m_shadowProjectionMatrix * shadowModelViewMatrix;
    }

    {
        // When calculating texture coordinates to sample from shadow map, flip the y/t coordinate and
        // convert from the [-1, 1] range of clip coordinates to [0, 1] range of
        // used for texture sampling
        float4x4 shadowScale = matrix4x4_scale(0.5f, -0.5f, 1.0);
        float4x4 shadowTranslate = matrix4x4_translation(0.5, 0.5, 0);
        float4x4 shadowTransform = shadowTranslate * shadowScale;

        frameData->shadow_mvp_xform_matrix = shadowTransform * frameData->shadow_mvp_matrix;
    }

    frameData->fairy_size = .4;

    updateLights( frameData->temple_modelview_matrix );
}

/// Called whenever view changes orientation or layout is changed
void Renderer::drawableSizeWillChange(const MTL::Size& size, MTL::StorageMode GBufferStorageMode)
{
    // When reshape is called, update the aspect ratio and projection matrix since the view
    //   orientation or size has changed
    float aspect = (float)size.width / (float)size.height;
    m_projection_matrix = matrix_perspective_left_hand(65.0f * (M_PI / 180.0f), aspect, NearPlane, FarPlane);

    MTL::TextureDescriptor* pGBufferTextureDesc = MTL::TextureDescriptor::alloc()->init();

    pGBufferTextureDesc->setPixelFormat( MTL::PixelFormatRGBA8Unorm_sRGB );
    pGBufferTextureDesc->setWidth( size.width );
    pGBufferTextureDesc->setHeight( size.height );
    pGBufferTextureDesc->setMipmapLevelCount( 1 );
    pGBufferTextureDesc->setTextureType( MTL::TextureType2D );

    if(GBufferStorageMode == MTL::StorageModePrivate)
    {
        pGBufferTextureDesc->setUsage( MTL::TextureUsageRenderTarget | MTL::TextureUsageShaderRead );
    }
    else
    {
        pGBufferTextureDesc->setUsage( MTL::TextureUsageRenderTarget );
    }

    pGBufferTextureDesc->setStorageMode( GBufferStorageMode );

    pGBufferTextureDesc->setPixelFormat( m_albedo_specular_GBufferFormat );
    m_albedo_specular_GBuffer = m_pDevice->newTexture( pGBufferTextureDesc );

    pGBufferTextureDesc->setPixelFormat( m_normal_shadow_GBufferFormat );
    m_normal_shadow_GBuffer = m_pDevice->newTexture( pGBufferTextureDesc );

    pGBufferTextureDesc->setPixelFormat( m_depth_GBufferFormat );
    m_depth_GBuffer = m_pDevice->newTexture( pGBufferTextureDesc );

    m_albedo_specular_GBuffer->setLabel( AAPLSTR( "Albedo + Shadow GBuffer" ) );
    m_normal_shadow_GBuffer->setLabel( AAPLSTR( "Normal + Specular GBuffer" ) );
    m_depth_GBuffer->setLabel( AAPLSTR( "Depth GBuffer" ) );
    
    pGBufferTextureDesc->release();
}

#pragma mark Common Rendering Code

/// Draw the mesh objects with the given renderEncoder.
void Renderer::drawMeshes( MTL::RenderCommandEncoder* pRenderEncoder )
{
    for (auto& mesh : m_meshes)
    {
        for (auto& meshBuffer : mesh.vertexBuffers())
        {
            pRenderEncoder->setVertexBuffer( meshBuffer.buffer(),
                                           meshBuffer.offset(),
                                           meshBuffer.argumentIndex() );
        }

        for (auto& submesh : mesh.submeshes())
        {
            // Set any textures read/sampled from the render pipeline
            const auto& submeshTextures = submesh.textures();

            pRenderEncoder->setFragmentTexture( submeshTextures[TextureIndexBaseColor], TextureIndexBaseColor );

            pRenderEncoder->setFragmentTexture( submeshTextures[TextureIndexNormal], TextureIndexNormal );

            pRenderEncoder->setFragmentTexture( submeshTextures[TextureIndexSpecular], TextureIndexSpecular );

            pRenderEncoder->drawIndexedPrimitives( submesh.primitiveType(),
                                                 submesh.indexCount(),
                                                 submesh.indexType(),
                                                 submesh.indexBuffer().buffer(),
                                                 submesh.indexBuffer().offset() );
        }
    }
}

/// Get a drawable from the view (or hand back an offscreen drawable for buffer examination mode)
MTL::Texture* Renderer::currentDrawableTexture( MTL::Drawable* pCurrentDrawable )
{
#if SUPPORT_BUFFER_EXAMINATION
    if(m_bufferExaminationManager->mode())
    {
        return m_bufferExaminationManager->offscreenDrawable();
    }
#endif // SUPPORT_BUFFER_EXAMINATION

    if(pCurrentDrawable)
    {
        auto pMtlDrawable = static_cast< CA::MetalDrawable* >(pCurrentDrawable);
        return pMtlDrawable->texture();
    }

    return nullptr;
}

/// Perform operations necessary at the beginning of the frame. Wait on the in-flight semaphore,
/// and get a command buffer to encode initial commands for this frame.
MTL::CommandBuffer* Renderer::beginFrame( bool isPaused )
{
    // Wait to ensure only MaxFramesInFlight are getting processed by any stage in the Metal
    // pipeline (App, Metal, Drivers, GPU, etc)

    dispatch_semaphore_wait(this->m_inFlightSemaphore, DISPATCH_TIME_FOREVER);

    // Create a new command buffer for each render pass to the current drawable
    MTL::CommandBuffer* pCommandBuffer = m_pCommandQueue->commandBuffer();

    updateWorldState( isPaused );

    return pCommandBuffer;
}

/// Perform operations necessary to obtain a command buffer for rendering to the drawable. By
/// endoding commands that are not dependant on the drawable in a separate command buffer, Metal
/// can begin executing encoded commands for the frame (commands from the previous command buffer)
/// before a drawable for this frame becomes available.
MTL::CommandBuffer* Renderer::beginDrawableCommands()
{
    MTL::CommandBuffer* pCommandBuffer = m_pCommandQueue->commandBuffer();

    // Create a completed handler functor for Metal to execute when the GPU has fully finished
    // processing the commands encoded for this frame. This implenentation of the completed
    // handler signals the `m_inFlightSemaphore`, which indicates that the GPU is no longer
    // accessing the the dynamic buffer written to this frame. When the GPU no longer accesses the
    // buffer, the renderer can safely overwrite the buffer's contents with data for a future frame.

    pCommandBuffer->addCompletedHandler([this]( MTL::CommandBuffer* ){
        dispatch_semaphore_signal( m_inFlightSemaphore );
    });

    return pCommandBuffer;
}

/// Perform cleanup operations including presenting the drawable and committing the command buffer
/// for the current frame.  Also, when enabled, draw buffer examination elements before all this.
void Renderer::endFrame(MTL::CommandBuffer* pCommandBuffer, MTL::Drawable* pCurrentDrawable)
{
#if SUPPORT_BUFFER_EXAMINATION
    if( m_bufferExaminationManager->mode() )
    {
        m_bufferExaminationManager->drawAndPresentBuffersWithCommandBuffer( pCommandBuffer );
    }
#endif

    // Schedule a present once the framebuffer is complete using the current drawable
    if( pCurrentDrawable )
    {
        // Create a scheduled handler functor for Metal to present the drawable when the command
        // buffer has been scheduled by the kernel.

        pCurrentDrawable->retain();
        pCommandBuffer->addScheduledHandler( [pCurrentDrawable]( MTL::CommandBuffer* ){
            pCurrentDrawable->present();
            pCurrentDrawable->release();
        });
    }

    // Finalize rendering here & push the command buffer to the GPU
    pCommandBuffer->commit();
}

/// Draw to the depth texture from the directional lights point of view to generate the shadow map
void Renderer::drawShadow(MTL::CommandBuffer* pCommandBuffer)
{
    MTL::RenderCommandEncoder* pEncoder = pCommandBuffer->renderCommandEncoder(m_pShadowRenderPassDescriptor);

    pEncoder->setLabel( AAPLSTR( "Shadow Map Pass" ) );

    pEncoder->setRenderPipelineState( m_pShadowGenPipelineState );
    pEncoder->setDepthStencilState( m_pShadowDepthStencilState );
    pEncoder->setCullMode( MTL::CullModeBack );
    pEncoder->setDepthBias( 0.015, 7, 0.02 );

    pEncoder->setVertexBuffer( m_frameDataBuffers[m_frameDataBufferIndex], 0, BufferIndexFrameData );

    drawMeshes( pEncoder );

    pEncoder->endEncoding();
}

/// Draw to the three textures which compose the GBuffer
void Renderer::drawGBuffer(MTL::RenderCommandEncoder* pRenderEncoder)
{
    pRenderEncoder->pushDebugGroup( AAPLSTR( "Geometry buffer render pass" ) );
    pRenderEncoder->setCullMode( MTL::CullModeBack );
    pRenderEncoder->setRenderPipelineState( m_pGBufferPipelineState );
    pRenderEncoder->setDepthStencilState( m_pGBufferDepthStencilState );
    pRenderEncoder->setStencilReferenceValue( 128 );
    pRenderEncoder->setVertexBuffer( m_frameDataBuffers[m_frameDataBufferIndex], 0, BufferIndexFrameData );
    pRenderEncoder->setFragmentBuffer( m_frameDataBuffers[m_frameDataBufferIndex], 0, BufferIndexFrameData );
    pRenderEncoder->setFragmentTexture( m_pShadowMap, TextureIndexShadow );

    drawMeshes( pRenderEncoder );
    pRenderEncoder->popDebugGroup();
}

/// Draw the directional ("sun") light in deferred pass.  Use stencil buffer to limit execution
/// of the shader to only those pixels that should be lit
void Renderer::drawDirectionalLightCommon(MTL::RenderCommandEncoder* pRenderEncoder)
{
    pRenderEncoder->setCullMode( MTL::CullModeBack );
    pRenderEncoder->setStencilReferenceValue( 128 );

    pRenderEncoder->setRenderPipelineState( m_pDirectionalLightPipelineState );
    pRenderEncoder->setDepthStencilState( m_pDirectionLightDepthStencilState );
    pRenderEncoder->setVertexBuffer( m_pQuadVertexBuffer, 0, BufferIndexMeshPositions );
    pRenderEncoder->setVertexBuffer( m_frameDataBuffers[m_frameDataBufferIndex], 0, BufferIndexFrameData );
    pRenderEncoder->setFragmentBuffer( m_frameDataBuffers[m_frameDataBufferIndex], 0, BufferIndexFrameData );

    // Draw full screen quad
    pRenderEncoder->drawPrimitives( MTL::PrimitiveTypeTriangle, (NS::UInteger)0, (NS::UInteger)6 );
}

/// Render to stencil buffer only to increment stencil on that fragments in front
/// of the backside of each light volume
void Renderer::drawPointLightMask(MTL::RenderCommandEncoder* pRenderEncoder)
{
#if LIGHT_STENCIL_CULLING
    pRenderEncoder->pushDebugGroup( AAPLSTR( "Draw Light Mask" ) );
    pRenderEncoder->setRenderPipelineState( m_pLightMaskPipelineState );
    pRenderEncoder->setDepthStencilState( m_pLightMaskDepthStencilState );

    pRenderEncoder->setStencilReferenceValue( 128 );
    pRenderEncoder->setCullMode( MTL::CullModeFront );

    pRenderEncoder->setVertexBuffer( m_frameDataBuffers[m_frameDataBufferIndex], 0, BufferIndexFrameData );
    pRenderEncoder->setFragmentBuffer( m_frameDataBuffers[m_frameDataBufferIndex], 0, BufferIndexFrameData );
    pRenderEncoder->setVertexBuffer( m_pLightsData, 0, BufferIndexLightsData );
    pRenderEncoder->setVertexBuffer( m_lightPositions[m_frameDataBufferIndex], 0, BufferIndexLightsPosition );

    const std::vector<MeshBuffer>& vertexBuffers = m_icosahedronMesh.vertexBuffers();
    pRenderEncoder->setVertexBuffer( vertexBuffers[0].buffer(), vertexBuffers[0].offset(), BufferIndexMeshPositions );

    const std::vector<Submesh>& icosahedronSubmesh = m_icosahedronMesh.submeshes();

    pRenderEncoder->drawIndexedPrimitives( icosahedronSubmesh[0].primitiveType(),
                                         icosahedronSubmesh[0].indexCount(),
                                         icosahedronSubmesh[0].indexType(),
                                         icosahedronSubmesh[0].indexBuffer().buffer(),
                                         icosahedronSubmesh[0].indexBuffer().offset(),
                                         NumLights );

    pRenderEncoder->popDebugGroup();
#endif
}

/// Performs operations common to both single-pass and traditional deferred renders for drawing point lights.
/// Called by derived renderer classes  after they have set up any renderer specific specific state
/// (such as setting GBuffer textures with the traditional deferred renderer not needed for the single-pass renderer)
void Renderer::drawPointLightsCommon(MTL::RenderCommandEncoder* pRenderEncoder)
{
    pRenderEncoder->setDepthStencilState( m_pPointLightDepthStencilState );

    pRenderEncoder->setStencilReferenceValue( 128 );
    pRenderEncoder->setCullMode( MTL::CullModeBack );

    pRenderEncoder->setVertexBuffer( m_frameDataBuffers[m_frameDataBufferIndex], 0, BufferIndexFrameData );
    pRenderEncoder->setVertexBuffer( m_pLightsData, 0, BufferIndexLightsData );
    pRenderEncoder->setVertexBuffer( m_lightPositions[m_frameDataBufferIndex], 0, BufferIndexLightsPosition );

    pRenderEncoder->setFragmentBuffer( m_frameDataBuffers[m_frameDataBufferIndex], 0, BufferIndexFrameData );
    pRenderEncoder->setFragmentBuffer( m_pLightsData, 0, BufferIndexLightsData );
    pRenderEncoder->setFragmentBuffer( m_lightPositions[m_frameDataBufferIndex], 0, BufferIndexLightsPosition );

    const std::vector<MeshBuffer>& vertexBuffers = m_icosahedronMesh.vertexBuffers();
    pRenderEncoder->setVertexBuffer( vertexBuffers[0].buffer(), vertexBuffers[0].offset(), BufferIndexMeshPositions );

    const std::vector<Submesh>& icosahedronSubmesh = m_icosahedronMesh.submeshes();

    pRenderEncoder->drawIndexedPrimitives( icosahedronSubmesh[0].primitiveType(),
                                         icosahedronSubmesh[0].indexCount(),
                                         icosahedronSubmesh[0].indexType(),
                                         icosahedronSubmesh[0].indexBuffer().buffer(),
                                         icosahedronSubmesh[0].indexBuffer().offset(),
                                         NumLights );
}

/// Draw the "fairies" at the center of the point lights with a 2D disk using a texture to perform
/// smooth alpha blending on the edges
void Renderer::drawFairies(MTL::RenderCommandEncoder* pRenderEncoder)
{
    pRenderEncoder->pushDebugGroup( AAPLSTR( "Draw Fairies" ) );
    pRenderEncoder->setRenderPipelineState( m_pFairyPipelineState );
    pRenderEncoder->setDepthStencilState( m_pDontWriteDepthStencilState );
    pRenderEncoder->setCullMode( MTL::CullModeBack );
    pRenderEncoder->setVertexBuffer( m_frameDataBuffers[m_frameDataBufferIndex], 0, BufferIndexFrameData );
    pRenderEncoder->setVertexBuffer( m_pFairy, 0, BufferIndexMeshPositions );
    pRenderEncoder->setVertexBuffer( m_pLightsData, 0, BufferIndexLightsData );
    pRenderEncoder->setVertexBuffer( m_lightPositions[m_frameDataBufferIndex], 0, BufferIndexLightsPosition );
    pRenderEncoder->setFragmentTexture( m_pFairyMap, TextureIndexAlpha );
    pRenderEncoder->drawPrimitives( MTL::PrimitiveTypeTriangleStrip, 0, NumFairyVertices, NumLights );
    pRenderEncoder->popDebugGroup();
}

/// Draw the sky dome behind all other geometry (testing against depth buffer generated in
///  GBuffer pass)
void Renderer::drawSky(MTL::RenderCommandEncoder* pRenderEncoder)
{
    pRenderEncoder->pushDebugGroup( AAPLSTR( "Draw Sky" ) );
    pRenderEncoder->setRenderPipelineState( m_pSkyboxPipelineState );
    pRenderEncoder->setDepthStencilState( m_pDontWriteDepthStencilState );
    pRenderEncoder->setCullMode( MTL::CullModeFront );

    pRenderEncoder->setVertexBuffer( m_frameDataBuffers[m_frameDataBufferIndex], 0, BufferIndexFrameData );
    pRenderEncoder->setFragmentTexture( m_pSkyMap, TextureIndexBaseColor );

    for (auto& meshBuffer : m_skyMesh.vertexBuffers())
    {
        pRenderEncoder->setVertexBuffer(meshBuffer.buffer(),
                                        meshBuffer.offset(),
                                        meshBuffer.argumentIndex());
    }


    for (auto& submesh : m_skyMesh.submeshes())
    {
        pRenderEncoder->drawIndexedPrimitives(submesh.primitiveType(),
                                              submesh.indexCount(),
                                              submesh.indexType(),
                                              submesh.indexBuffer().buffer(),
                                              submesh.indexBuffer().offset() );
    }
    pRenderEncoder->popDebugGroup();
}
