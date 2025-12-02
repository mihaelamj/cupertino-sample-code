/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the renderer class that performs Metal set up and per-frame rendering.
*/

#pragma once

@import MetalKit;

@interface AAPLRenderer : NSObject

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView*)mtkView;

- (void)mtkView:(nonnull MTKView*)view drawableSizeWillChange:(CGSize)size;

- (void)drawInMTKView:(nonnull MTKView*)view;

/// This property is used to animate the ground plane backwards and forwards.
@property (nonatomic) bool animationEnabled;

/// This property is used to report the memory usage for the sparse texture.
@property (nonatomic, nonnull) NSString* infoString;

@end
