/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This class forwards Objective-C view draw and resize methods to the C++ renderer class.
*/

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>

@class MTKView;

@interface AAPLRendererAdapter : NSObject

- (instancetype)initWithMtkView:(MTKView*)pMtkView;
- (void*)device;
- (void)drawInMTKView:(MTKView*)pMtkView;
- (void)drawableSizeWillChange:(CGSize)size;
- (void)setRotationSpeed:(float)speed;
- (void)setTranslation:(float)offsetZ offsetY:(float)offsetY;
- (void)setLODChoice:(int)lodChoice;
- (void)setTopologyChoice:(int)topologyChoice;

@end
