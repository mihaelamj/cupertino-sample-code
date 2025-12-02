/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A platform independent renderer class
*/

#import <MetalKit/MetalKit.h>
#include "ShaderTypes.h"

// Our platform independent renderer class.   Implements the MTKViewDelegate protocol which
//   allows it to accept per-frame update and drawable resize callbacks.
@interface Renderer : NSObject <MTKViewDelegate>

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;

-(void)setTransparency:(float)value;
-(void)setBlendMode:(BlendMode)mode;

@end

