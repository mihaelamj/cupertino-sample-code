/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for renderer class that performs Metal setup and per-frame rendering.
*/
#ifndef AAPLRenderer_BufferExaminationManager_h
#define AAPLRenderer_BufferExaminationManager_h

#include "AAPLConfig.h"

#if SUPPORT_BUFFER_EXAMINATION

#include <Metal/Metal.hpp>
#include <forward_list>
#include "AAPLViewAdapter.h"

class Renderer;

typedef enum ExaminationMode
{
    ExaminationModeDisabled           = 0x00,
    ExaminationModeAlbedo             = 0x01,
    ExaminationModeNormals            = 0x02,
    ExaminationModeSpecular           = 0x04,
    ExaminationModeDepth              = 0x08,
    ExaminationModeShadowGBuffer      = 0x10,
    ExaminationModeShadowMap          = 0x20,
    ExaminationModeMaskedLightVolumes = 0x40,
    ExaminationModeFullLightVolumes   = 0x80,
    ExaminationModeAll                = 0xFF
} ExaminationMode;

class BufferExaminationManager
{
public:

    BufferExaminationManager(const Renderer& renderer,
                             const AAPLViewAdapter& albedoGBufferView,
                             const AAPLViewAdapter& normalsGBufferView,
                             const AAPLViewAdapter& depthGBufferView,
                             const AAPLViewAdapter& shadowGBufferView,
                             const AAPLViewAdapter& finalFrameView,
                             const AAPLViewAdapter& specularGBufferView,
                             const AAPLViewAdapter& shadowMapView,
                             const AAPLViewAdapter& lightMaskView,
                             const AAPLViewAdapter& lightCoverageView,
                             const AAPLViewAdapter& rendererView);

    BufferExaminationManager(const BufferExaminationManager & rhs) = delete;

    BufferExaminationManager & operator=(const BufferExaminationManager & rhs) = delete;

    virtual ~BufferExaminationManager();

    void updateDrawableSize(MTL::Size size);

    void drawAndPresentBuffersWithCommandBuffer(MTL::CommandBuffer* pCommandBuffer);

    MTL::Texture *offscreenDrawable() const;

    void mode(ExaminationMode mode);
    ExaminationMode mode() const;

private:

    void loadMetalState();

    void drawAlbedoGBufferWithCommandBuffer  (MTL::CommandBuffer* pCommandBuffer);
    void drawNormalsGBufferWithCommandBuffer (MTL::CommandBuffer* pCommandBuffer);
    void drawDepthGBufferWithCommandBuffer   (MTL::CommandBuffer* pCommandBuffer);
    void drawShadowGBufferWithCommandBuffer  (MTL::CommandBuffer* pCommandBuffer);
    void drawFinalRenderWithCommandBuffer    (MTL::CommandBuffer* pCommandBuffer);
    void drawSpecularGBufferWithCommandBuffer(MTL::CommandBuffer* pCommandBuffer);
    void drawShadowMapWithCommandBuffer      (MTL::CommandBuffer* pCommandBuffer);
    void drawLightMaskWithCommandBuffer      (MTL::CommandBuffer* pCommandBuffer);
    void drawLightVolumesWithCommandBuffer   (MTL::CommandBuffer* pCommandBuffer);

    void renderLightVolumesExaminationWithCommandBuffer(MTL::CommandBuffer* pCommandBuffer,
                                                        bool fullVolumes);

    const Renderer& m_renderer;

    MTL::Device* m_pDevice;

    ExaminationMode m_mode;

    AAPLViewAdapter m_albedoGBufferView;
    AAPLViewAdapter m_normalsGBufferView;
    AAPLViewAdapter m_depthGBufferView;
    AAPLViewAdapter m_shadowGBufferView;
    AAPLViewAdapter m_finalFrameView;
    AAPLViewAdapter m_specularGBufferView;
    AAPLViewAdapter m_shadowMapView;
    AAPLViewAdapter m_lightMaskView;
    AAPLViewAdapter m_lightCoverageView;
    AAPLViewAdapter m_rendererView;

    MTL::Texture* m_offscreenDrawable;
    MTL::Texture* m_lightVolumeTarget;

    std::forward_list< AAPLViewAdapter* > m_allViews;

    MTL::RenderPipelineState* m_textureDepthPipelineState;
    MTL::RenderPipelineState* m_textureRGBPipelineState;
    MTL::RenderPipelineState* m_textureAlphaPipelineState;

    // A render pipeline state used to visualize the point light volume coverage and fragments
    // culled using the stencil test.
    MTL::RenderPipelineState* m_lightVolumeVisualizationPipelineState;

    /// The depth stencil state the app uses to create point light volume coverage visualization buffers.
    MTL::DepthStencilState* m_depthTestOnlyDepthStencilState;
};

inline ExaminationMode BufferExaminationManager::mode() const
{
    return m_mode;
}

inline MTL::Texture *BufferExaminationManager::offscreenDrawable() const
{
    return m_offscreenDrawable;
}

#endif // SUPPORT_BUFFER_EXAMINATION

#endif // AAPLRenderer_BufferExaminationManager_h

