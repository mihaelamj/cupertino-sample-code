/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This class forwards the view draw and resize methods to the C++ renderer class.
*/

#if __has_feature(objc_arc)
#error This file must be compiled with -fno-objc-arc
#endif

#import "AAPLRendererAdapter.h"

#define NS_PRIVATE_IMPLEMENTATION
#define MTL_PRIVATE_IMPLEMENTATION
#define CA_PRIVATE_IMPLEMENTATION
#define MTK_PRIVATE_IMPLEMENTATION

#include "Foundation/Foundation.hpp"
#include "QuartzCore/QuartzCore.hpp"
#include "Metal/Metal.hpp"

#include "AAPLRenderer.hpp"

@interface AAPLRendererAdapter ()
{
    AAPLRenderer* _pRenderer;
    MTL::Device* _pDevice;
}
@end

@implementation AAPLRendererAdapter

- (instancetype)initWithMtkView:(MTKView*)pMtkView
{
    if ( self = [super init] )
    {
        _pDevice = MTL::CreateSystemDefaultDevice();
        _pRenderer = new AAPLRenderer( *((__bridge MTK::View *)pMtkView) );
    }
    return self;
}

- (void)dealloc
{
    _pDevice->release();
    [super dealloc];
}

- (void *)device
{
    return (void *)_pDevice;
}

- (void)drawInMTKView:(MTKView*)pMtkView
{
    _pRenderer->draw((__bridge MTK::View*)pMtkView);
}

- (void)drawableSizeWillChange:(CGSize)size
{
    _pRenderer->drawableSizeWillChange(size);
}

- (void)setRotationSpeed:(float)speed
{
    _pRenderer->rotationSpeed = speed;
}

- (void)setTranslation:(float)offsetZ offsetY:(float)offsetY
{
    _pRenderer->offsetZ = offsetZ;
    _pRenderer->offsetY = offsetY;
}

- (void)setLODChoice:(int)lodChoice
{
    _pRenderer->lodChoice = lodChoice;
}

- (void)setTopologyChoice:(int)topologyChoice
{
    _pRenderer->topologyChoice = topologyChoice;
}

@end
