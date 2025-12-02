/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for adapter class that allows requesting actions from a MTKView.
*/

#include "AAPLViewAdapter.h"
#import <MetalKit/MetalKit.h>
#include <QuartzCore/CAMetalDrawable.hpp>

AAPLViewAdapter::AAPLViewAdapter( void* pMTKView )
: m_pMTKView( pMTKView )
{
    
}

AAPLViewAdapter::AAPLViewAdapter( const AAPLViewAdapter& rhs )
: m_pMTKView( rhs.m_pMTKView )
{
    
}

AAPLViewAdapter& AAPLViewAdapter::operator=( const AAPLViewAdapter& rhs )
{
    m_pMTKView = rhs.m_pMTKView;
    return *this;
}

CA::MetalDrawable* AAPLViewAdapter::currentDrawable() const
{
    return (__bridge CA::MetalDrawable*)[(__bridge MTKView *)m_pMTKView currentDrawable];
}

MTL::Texture* AAPLViewAdapter::depthStencilTexture() const
{
    return (__bridge MTL::Texture*)[(__bridge MTKView *)m_pMTKView depthStencilTexture];
}

MTL::RenderPassDescriptor* AAPLViewAdapter::currentRenderPassDescriptor() const
{
    return (__bridge MTL::RenderPassDescriptor*)[(__bridge MTKView *)m_pMTKView currentRenderPassDescriptor];
}

std::tuple<CGFloat, CGFloat> AAPLViewAdapter::drawableSize() const
{
    CGSize size = [(__bridge MTKView *)m_pMTKView drawableSize];
    return std::make_tuple( size.width, size.height );
}

void AAPLViewAdapter::draw()
{
    [(__bridge MTKView*)m_pMTKView draw];
}

void AAPLViewAdapter::setHidden( bool hidden )
{
    [(__bridge MTKView*)m_pMTKView setHidden:hidden];
}

void AAPLViewAdapter::setPaused( bool paused )
{
    [(__bridge MTKView*)m_pMTKView setPaused:paused];
}

void AAPLViewAdapter::setColorPixelFormat( MTL::PixelFormat colorPixelFormat )
{
    [(__bridge MTKView*)m_pMTKView setColorPixelFormat:(MTLPixelFormat)colorPixelFormat];
}
