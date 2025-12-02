/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for adapter class that allows requesting actions from a MTKView.
*/
#ifndef AAPLVIEWADAPTER_H
#define AAPLVIEWADAPTER_H

#include <Metal/MTLPixelFormat.hpp>
#include <tuple>
#include <CoreGraphics/CGBase.h>

namespace CA
{
    class MetalDrawable;
}

namespace MTL
{
    class Texture;
    class RenderPassDescriptor;
}

class AAPLViewAdapter
{
public:
    explicit AAPLViewAdapter( void* pMTKView );
    
    AAPLViewAdapter( const AAPLViewAdapter& );
    AAPLViewAdapter& operator=( const AAPLViewAdapter& );
    
    AAPLViewAdapter( AAPLViewAdapter&& ) = delete;
    AAPLViewAdapter& operator=( AAPLViewAdapter&& ) = delete;
    
    CA::MetalDrawable* currentDrawable() const;
    MTL::Texture* depthStencilTexture() const;
    MTL::RenderPassDescriptor* currentRenderPassDescriptor() const;
    std::tuple<CGFloat, CGFloat> drawableSize() const;
    
    void draw();
    
    void setHidden( bool hidden );
    void setPaused( bool paused );
    void setColorPixelFormat( MTL::PixelFormat );
    
private:
    void *m_pMTKView;
};

#endif //AAPLVIEWADAPTER_H
