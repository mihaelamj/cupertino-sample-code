/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for the renderer class that performs Metal setup and per-frame rendering for a traditional
 deferred renderer used for macOS devices without Apple silicon and the iOS and tvOS simulators.
*/

#ifndef AAPLRenderer_TraditionalDeferred_h
#define AAPLRenderer_TraditionalDeferred_h

#include "AAPLRenderer.h"

#include <Metal/Metal.hpp>

class Renderer_TraditionalDeferred : public Renderer
{
public:

    explicit Renderer_TraditionalDeferred( MTL::Device* pDevice );

    virtual ~Renderer_TraditionalDeferred() override;

    virtual void drawInView( bool isPaused, MTL::Drawable* pCurrentDrawable, MTL::Texture* pDepthStencilTexture ) override;

    virtual void drawableSizeWillChange(const MTL::Size& size, MTL::StorageMode GBufferStorageMode) override;

#if SUPPORT_BUFFER_EXAMINATION

    virtual void validateBufferExaminationMode() override;

#endif

private:

    MTL::RenderPipelineState* m_pLightPipelineState;

    MTL::RenderPassDescriptor* m_pGBufferRenderPassDescriptor;
    MTL::RenderPassDescriptor* m_pFinalRenderPassDescriptor;

    void loadMetalInternal();

    void drawDirectionalLight(MTL::RenderCommandEncoder* renderEncoder);

    void drawPointLights(MTL::RenderCommandEncoder* renderEncoder);

};
#endif // AAPLRenderer_TraditionalDeferred_h
