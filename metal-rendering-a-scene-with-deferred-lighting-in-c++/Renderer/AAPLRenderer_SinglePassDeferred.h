/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for the renderer class which performs Metal setup and per frame rendering for a single pass
 deferred renderer used for iOS and tvOS devices in addition to macOS devices with Apple silicon.
*/

#ifndef AAPLRenderer_SinglePassDeferred_h
#define AAPLRenderer_SinglePassDeferred_h

#include "AAPLRenderer.h"

class Renderer_SinglePassDeferred : public Renderer
{
public:

    explicit Renderer_SinglePassDeferred( MTL::Device* pDevice );
    
    virtual ~Renderer_SinglePassDeferred() override;

    virtual void drawInView( bool isPaused, MTL::Drawable* pCurrentDrawable, MTL::Texture* pDepthStencilTexture ) override;
    
    virtual void drawableSizeWillChange(const MTL::Size& size, MTL::StorageMode GBufferStorageMode) override;

#if SUPPORT_BUFFER_EXAMINATION

    virtual void validateBufferExaminationMode() override;

#endif

private:

    void loadMetalInternal();

    void drawDirectionalLight(MTL::RenderCommandEncoder* pRenderEncoder);

    void drawPointLights(MTL::RenderCommandEncoder* pRenderEncoder);

    MTL::RenderPipelineState* m_pLightPipelineState;

    MTL::RenderPassDescriptor* m_pViewRenderPassDescriptor;

    MTL::StorageMode m_GBufferStorageMode;
    
    MTL::Size m_drawableSize;
};

#endif // AAPLRenderer_SinglePassDeferred_h
